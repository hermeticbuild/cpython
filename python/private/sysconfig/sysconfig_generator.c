#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef enum {
  VALUE_INTEGER,
  VALUE_STRING,
} ValueKind;

typedef struct {
  char *name;
  char *value;
  ValueKind kind;
  bool from_build_vars;
} Variable;

typedef struct {
  Variable *items;
  size_t length;
  size_t capacity;
} Variables;

static void fail(const char *message, const char *detail) {
  if (detail != NULL) {
    fprintf(stderr, "sysconfig_generator: %s: %s\n", message, detail);
  } else {
    fprintf(stderr, "sysconfig_generator: %s\n", message);
  }
  exit(EXIT_FAILURE);
}

static void *allocate(size_t size) {
  void *result = malloc(size);
  if (result == NULL) {
    fail("out of memory", NULL);
  }
  return result;
}

static bool read_line(FILE *input, char **line, size_t *capacity) {
  if (*line == NULL) {
    *capacity = 256;
    *line = allocate(*capacity);
  }

  size_t length = 0;
  int character;
  while ((character = fgetc(input)) != EOF) {
    if (length + 1 >= *capacity) {
      size_t new_capacity = *capacity * 2;
      char *new_line = realloc(*line, new_capacity);
      if (new_line == NULL) {
        fail("out of memory", NULL);
      }
      *line = new_line;
      *capacity = new_capacity;
    }
    (*line)[length++] = (char)character;
    if (character == '\n') {
      break;
    }
  }
  if (length == 0 && character == EOF) {
    return false;
  }
  (*line)[length] = '\0';
  return true;
}

static char *duplicate_range(const char *begin, size_t length) {
  char *result = allocate(length + 1);
  memcpy(result, begin, length);
  result[length] = '\0';
  return result;
}

static bool ascii_alpha(unsigned char character) {
  return (character >= 'A' && character <= 'Z') ||
         (character >= 'a' && character <= 'z');
}

static bool ascii_digit(unsigned char character) {
  return character >= '0' && character <= '9';
}

static bool ascii_space(unsigned char character) {
  return character == ' ' || character == '\t' || character == '\n' ||
         character == '\r' || character == '\v' || character == '\f';
}

static bool valid_name(const char *name) {
  const unsigned char *cursor = (const unsigned char *)name;
  if (!(ascii_alpha(*cursor) || *cursor == '_')) {
    return false;
  }
  for (++cursor; *cursor != '\0'; ++cursor) {
    if (!(ascii_alpha(*cursor) || ascii_digit(*cursor) || *cursor == '_')) {
      return false;
    }
  }
  return true;
}

static Variable *find_variable(Variables *variables, const char *name) {
  for (size_t index = 0; index < variables->length; ++index) {
    if (strcmp(variables->items[index].name, name) == 0) {
      return &variables->items[index];
    }
  }
  return NULL;
}

static const Variable *require_variable(Variables *variables,
                                        const char *name) {
  Variable *variable = find_variable(variables, name);
  if (variable == NULL) {
    fail("missing required configuration variable", name);
  }
  return variable;
}

static void set_config_variable(Variables *variables, char *name, char *value,
                                ValueKind kind) {
  Variable *existing = find_variable(variables, name);
  if (existing != NULL) {
    free(existing->value);
    existing->value = value;
    existing->kind = kind;
    free(name);
    return;
  }
  if (variables->length == variables->capacity) {
    size_t capacity = variables->capacity == 0 ? 128 : variables->capacity * 2;
    Variable *items = realloc(variables->items, capacity * sizeof(*items));
    if (items == NULL) {
      fail("out of memory", NULL);
    }
    variables->items = items;
    variables->capacity = capacity;
  }
  variables->items[variables->length++] = (Variable){
      .name = name,
      .value = value,
      .kind = kind,
      .from_build_vars = false,
  };
}

static void set_string_variable(Variables *variables, const char *name,
                                const char *value) {
  set_config_variable(variables, duplicate_range(name, strlen(name)),
                      duplicate_range(value, strlen(value)), VALUE_STRING);
}

static void remove_variable(Variables *variables, const char *name) {
  for (size_t index = 0; index < variables->length; ++index) {
    Variable *variable = &variables->items[index];
    if (strcmp(variable->name, name) != 0) {
      continue;
    }
    free(variable->name);
    free(variable->value);
    memmove(variable, variable + 1,
            (variables->length - index - 1) * sizeof(*variable));
    --variables->length;
    return;
  }
}

static bool variable_is_true(Variables *variables, const char *name) {
  Variable *variable = find_variable(variables, name);
  return variable != NULL && strcmp(variable->value, "0") != 0 &&
         variable->value[0] != '\0';
}

static bool always_string(const char *name) {
  return strcmp(name, "IPHONEOS_DEPLOYMENT_TARGET") == 0 ||
         strcmp(name, "MACOSX_DEPLOYMENT_TARGET") == 0;
}

/* Normalize the ASCII decimal syntax accepted by Python's int(value). */
static char *normalized_integer(const char *value) {
  const unsigned char *begin = (const unsigned char *)value;
  while (ascii_space(*begin)) {
    ++begin;
  }
  const unsigned char *end = begin + strlen((const char *)begin);
  while (end > begin && ascii_space(end[-1])) {
    --end;
  }
  bool negative = false;
  if (begin < end && (*begin == '+' || *begin == '-')) {
    negative = *begin == '-';
    ++begin;
  }
  if (begin == end || !ascii_digit(*begin)) {
    return NULL;
  }

  bool previous_digit = false;
  size_t digit_count = 0;
  for (const unsigned char *cursor = begin; cursor < end; ++cursor) {
    if (ascii_digit(*cursor)) {
      previous_digit = true;
      ++digit_count;
    } else if (*cursor == '_' && previous_digit && cursor + 1 < end &&
               ascii_digit(cursor[1])) {
      previous_digit = false;
    } else {
      return NULL;
    }
  }

  const unsigned char *first_nonzero = NULL;
  for (const unsigned char *cursor = begin; cursor < end; ++cursor) {
    if (*cursor >= '1' && *cursor <= '9') {
      first_nonzero = cursor;
      break;
    }
  }
  if (first_nonzero == NULL) {
    return duplicate_range("0", 1);
  }

  char *result = allocate(digit_count + (negative ? 2 : 1));
  char *output = result;
  if (negative) {
    *output++ = '-';
  }
  for (const unsigned char *cursor = first_nonzero; cursor < end; ++cursor) {
    if (*cursor != '_') {
      *output++ = (char)*cursor;
    }
  }
  *output = '\0';
  return result;
}

static bool config_name(const char *begin, size_t length) {
  if (length < 2 || begin[0] < 'A' || begin[0] > 'Z') {
    return false;
  }
  for (size_t index = 1; index < length; ++index) {
    unsigned char character = (unsigned char)begin[index];
    if (!(ascii_alpha(character) || ascii_digit(character) ||
          character == '_')) {
      return false;
    }
  }
  return true;
}

static void parse_config_line(Variables *variables, const char *line) {
  size_t length = strlen(line);
  if (length == 0 || line[length - 1] != '\n') {
    return;
  }

  static const char define_prefix[] = "#define ";
  if (strncmp(line, define_prefix, sizeof(define_prefix) - 1) == 0) {
    const char *name_begin = line + sizeof(define_prefix) - 1;
    const char *name_end = strchr(name_begin, ' ');
    if (name_end == NULL ||
        !config_name(name_begin, (size_t)(name_end - name_begin))) {
      return;
    }
    char *name = duplicate_range(name_begin, (size_t)(name_end - name_begin));
    const char *value_begin = name_end + 1;
    size_t value_length = length - (size_t)(value_begin - line) - 1;
    char *value = duplicate_range(value_begin, value_length);
    char *integer = always_string(name) ? NULL : normalized_integer(value);
    if (integer != NULL) {
      free(value);
      value = integer;
      set_config_variable(variables, name, value, VALUE_INTEGER);
    } else {
      set_config_variable(variables, name, value, VALUE_STRING);
    }
    return;
  }

  static const char undef_prefix[] = "/* #undef ";
  static const char undef_suffix[] = " */\n";
  if (length <= sizeof(undef_prefix) - 1 + sizeof(undef_suffix) - 1 ||
      strncmp(line, undef_prefix, sizeof(undef_prefix) - 1) != 0 ||
      strcmp(line + length - (sizeof(undef_suffix) - 1), undef_suffix) != 0) {
    return;
  }
  const char *name_begin = line + sizeof(undef_prefix) - 1;
  size_t name_length =
      length - (sizeof(undef_prefix) - 1) - (sizeof(undef_suffix) - 1);
  if (!config_name(name_begin, name_length)) {
    return;
  }
  set_config_variable(variables, duplicate_range(name_begin, name_length),
                      duplicate_range("0", 1), VALUE_INTEGER);
}

static void parse_config_h(Variables *variables, const char *path) {
  FILE *input = fopen(path, "r");
  if (input == NULL) {
    fail("cannot open pyconfig.h", path);
  }
  char *line = NULL;
  size_t capacity = 0;
  while (read_line(input, &line, &capacity)) {
    parse_config_line(variables, line);
  }
  if (ferror(input)) {
    fail("cannot read pyconfig.h", path);
  }
  free(line);
  fclose(input);
}

static void parse_build_vars(Variables *variables, const char *path) {
  FILE *input = fopen(path, "r");
  if (input == NULL) {
    fail("cannot open build variable manifest", path);
  }
  char *line = NULL;
  size_t capacity = 0;
  while (read_line(input, &line, &capacity)) {
    size_t length = strlen(line);
    if (length == 0 || line[length - 1] != '\n') {
      fail("invalid build variable manifest line", line);
    }
    line[length - 1] = '\0';
    if ((line[0] != 'S' && line[0] != 'I') || line[1] != '\t') {
      fail("invalid build variable manifest type", line);
    }
    ValueKind kind = line[0] == 'I' ? VALUE_INTEGER : VALUE_STRING;
    char *name = line + 2;
    char *separator = strchr(name, '\t');
    if (separator == NULL) {
      fail("invalid build variable manifest line", line);
    }
    *separator = '\0';
    char *value = separator + 1;
    if (!valid_name(name)) {
      fail("invalid build variable name", name);
    }
    if (strncmp(name, "HAVE_", 5) == 0 || strncmp(name, "WITH_", 5) == 0) {
      fail("pyconfig.h must define public configuration variable", name);
    }
    if (find_variable(variables, name) != NULL) {
      fail("build variable duplicates pyconfig.h variable", name);
    }
    char *normalized_value = duplicate_range(value, strlen(value));
    if (kind == VALUE_INTEGER) {
      free(normalized_value);
      normalized_value = normalized_integer(value);
      if (normalized_value == NULL) {
        fail("invalid integer build variable", value);
      }
    }
    set_config_variable(variables, duplicate_range(name, strlen(name)),
                        normalized_value, kind);
    variables->items[variables->length - 1].from_build_vars = true;
  }
  if (ferror(input)) {
    fail("cannot read build variable manifest", path);
  }
  free(line);
  fclose(input);
}

static int compare_variables(const void *left, const void *right) {
  const Variable *left_variable = left;
  const Variable *right_variable = right;
  return strcmp(left_variable->name, right_variable->name);
}

static void write_python_string(FILE *output, const char *value) {
  fputc('\'', output);
  for (const unsigned char *cursor = (const unsigned char *)value;
       *cursor != '\0'; ++cursor) {
    switch (*cursor) {
    case '\\':
      fputs("\\\\", output);
      break;
    case '\'':
      fputs("\\'", output);
      break;
    case '\n':
      fputs("\\n", output);
      break;
    case '\r':
      fputs("\\r", output);
      break;
    case '\t':
      fputs("\\t", output);
      break;
    default:
      if (*cursor < 0x20 || *cursor >= 0x7f) {
        fprintf(output, "\\x%02x", *cursor);
      } else {
        fputc(*cursor, output);
      }
      break;
    }
  }
  fputc('\'', output);
}

static void write_json_string(FILE *output, const char *value) {
  fputc('"', output);
  for (const unsigned char *cursor = (const unsigned char *)value;
       *cursor != '\0'; ++cursor) {
    switch (*cursor) {
    case '\\':
      fputs("\\\\", output);
      break;
    case '"':
      fputs("\\\"", output);
      break;
    case '\b':
      fputs("\\b", output);
      break;
    case '\f':
      fputs("\\f", output);
      break;
    case '\n':
      fputs("\\n", output);
      break;
    case '\r':
      fputs("\\r", output);
      break;
    case '\t':
      fputs("\\t", output);
      break;
    default:
      if (*cursor < 0x20) {
        fprintf(output, "\\u%04x", *cursor);
      } else {
        fputc(*cursor, output);
      }
      break;
    }
  }
  fputc('"', output);
}

static FILE *open_output(const char *path) {
  FILE *output = fopen(path, "wb");
  if (output == NULL) {
    fail("cannot open output", path);
  }
  return output;
}

static void write_sysconfig_data(const Variables *variables, const char *path) {
  FILE *output = open_output(path);
  fputs("# Generated from pyconfig.h and Bazel build variables.\n", output);
  fputs("build_time_vars = {\n", output);
  for (size_t index = 0; index < variables->length; ++index) {
    const Variable *variable = &variables->items[index];
    fputs("    ", output);
    write_python_string(output, variable->name);
    fputs(": ", output);
    if (variable->kind == VALUE_INTEGER) {
      fputs(variable->value, output);
    } else {
      write_python_string(output, variable->value);
    }
    fputs(",\n", output);
  }
  fputs("}\n", output);
  if (fclose(output) != 0) {
    fail("cannot write sysconfig output", path);
  }
}

static void prepare_installed_variables(Variables *variables,
                                        const char *release, int major,
                                        int minor) {
  const char *prefix = require_variable(variables, "prefix")->value;
  const char *exec_prefix = require_variable(variables, "exec_prefix")->value;
  const char *abiflags = require_variable(variables, "ABIFLAGS")->value;
  const char *bindir = require_variable(variables, "BINDIR")->value;
  const char *libpl = require_variable(variables, "LIBPL")->value;
  const char *platlibdir = require_variable(variables, "PLATLIBDIR")->value;
  char version_short[32];
  char version_nodot[32];
  int version_short_length =
      snprintf(version_short, sizeof(version_short), "%d.%d", major, minor);
  int version_nodot_length =
      snprintf(version_nodot, sizeof(version_nodot), "%d%d", major, minor);
  if (version_short_length < 0 ||
      (size_t)version_short_length >= sizeof(version_short) ||
      version_nodot_length < 0 ||
      (size_t)version_nodot_length >= sizeof(version_nodot)) {
    fail("cannot format Python version", release);
  }

  set_string_variable(variables, "abi_thread",
                      variable_is_true(variables, "Py_GIL_DISABLED") ? "t"
                                                                     : "");
  set_string_variable(variables, "abiflags", abiflags);
  set_string_variable(variables, "base", prefix);
  set_string_variable(variables, "implementation", "Python");
  set_string_variable(variables, "implementation_lower", "python");
  set_string_variable(variables, "installed_base", prefix);
  set_string_variable(variables, "installed_platbase", exec_prefix);
  set_string_variable(variables, "platbase", exec_prefix);
  set_string_variable(variables, "platlibdir", platlibdir);
  set_string_variable(variables, "projectbase", bindir);
  set_string_variable(variables, "py_version", release);
  set_string_variable(variables, "py_version_nodot", version_nodot);
  set_string_variable(variables, "py_version_nodot_plat", "");
  set_string_variable(variables, "py_version_short", version_short);
  set_string_variable(variables, "srcdir", libpl);
  remove_variable(variables, "userbase");
  qsort(variables->items, variables->length, sizeof(*variables->items),
        compare_variables);
}

static void write_sysconfig_json(const Variables *variables, const char *path) {
  FILE *output = open_output(path);
  fputs("{\n", output);
  for (size_t index = 0; index < variables->length; ++index) {
    const Variable *variable = &variables->items[index];
    fputs("  ", output);
    write_json_string(output, variable->name);
    fputs(": ", output);
    if (variable->kind == VALUE_INTEGER) {
      fputs(variable->value, output);
    } else {
      write_json_string(output, variable->value);
    }
    fputs(index + 1 == variables->length ? "\n" : ",\n", output);
  }
  fputs("}\n", output);
  if (fclose(output) != 0) {
    fail("cannot write sysconfig JSON output", path);
  }
}

static void copy_test_subdirs(FILE *output, const char *template_path) {
  FILE *input = fopen(template_path, "r");
  if (input == NULL) {
    fail("cannot open Makefile template", template_path);
  }

  static const char prefix[] = "TESTSUBDIRS=";
  char *line = NULL;
  size_t capacity = 0;
  bool copying = false;
  bool found = false;
  while (read_line(input, &line, &capacity)) {
    if (!copying) {
      if (strncmp(line, prefix, sizeof(prefix) - 1) != 0) {
        continue;
      }
      copying = true;
      found = true;
    }

    fputs(line, output);
    size_t length = strlen(line);
    if (length < 2 || line[length - 2] != '\\' || line[length - 1] != '\n') {
      break;
    }
  }
  if (ferror(input)) {
    fail("cannot read Makefile template", template_path);
  }
  free(line);
  fclose(input);
  if (!found) {
    fail("Makefile template does not define TESTSUBDIRS", template_path);
  }
}

static void write_makefile(const Variables *variables,
                           const char *template_path, const char *path) {
  FILE *output = open_output(path);
  fputs("# Generated from Bazel build variables and Makefile.pre.in.\n",
        output);
  for (size_t index = 0; index < variables->length; ++index) {
    const Variable *variable = &variables->items[index];
    if (variable->from_build_vars) {
      fprintf(output, "%s=%s\n", variable->name, variable->value);
    }
  }
  copy_test_subdirs(output, template_path);
  if (fclose(output) != 0) {
    fail("cannot write Makefile output", path);
  }
}

static const char *optional_argument_value(int argc, char **argv,
                                           const char *name) {
  for (int index = 1; index + 1 < argc; index += 2) {
    if (strcmp(argv[index], name) == 0) {
      return argv[index + 1];
    }
  }
  return NULL;
}

static const char *argument_value(int argc, char **argv, const char *name) {
  const char *value = optional_argument_value(argc, argv, name);
  if (value != NULL) {
    return value;
  }
  fail("missing command-line argument", name);
  return NULL;
}

static bool known_argument(const char *name) {
  static const char *const names[] = {
      "--build-vars",    "--major",    "--makefile-out", "--makefile-template",
      "--minor",         "--pyconfig", "--release",      "--sysconfig-json-out",
      "--sysconfig-out",
  };
  for (size_t index = 0; index < sizeof(names) / sizeof(names[0]); ++index) {
    if (strcmp(name, names[index]) == 0) {
      return true;
    }
  }
  return false;
}

static void validate_arguments(int argc, char **argv) {
  if (argc < 7 || argc % 2 == 0) {
    fail("expected named command-line argument pairs", NULL);
  }
  for (int index = 1; index < argc; index += 2) {
    if (!known_argument(argv[index])) {
      fail("unknown command-line argument", argv[index]);
    }
    for (int previous = 1; previous < index; previous += 2) {
      if (strcmp(argv[previous], argv[index]) == 0) {
        fail("duplicate command-line argument", argv[index]);
      }
    }
  }
}

static int integer_argument(int argc, char **argv, const char *name) {
  const char *value = argument_value(argc, argv, name);
  char *end = NULL;
  long parsed = strtol(value, &end, 10);
  if (value[0] == '\0' || *end != '\0' || parsed < 0 || parsed > 0x7fffffffL) {
    fail("invalid nonnegative integer argument", name);
  }
  return (int)parsed;
}

int main(int argc, char **argv) {
  validate_arguments(argc, argv);
  const char *pyconfig = argument_value(argc, argv, "--pyconfig");
  const char *build_vars = argument_value(argc, argv, "--build-vars");
  const char *sysconfig_out = argument_value(argc, argv, "--sysconfig-out");

  Variables variables = {0};
  parse_config_h(&variables, pyconfig);
  parse_build_vars(&variables, build_vars);
  qsort(variables.items, variables.length, sizeof(*variables.items),
        compare_variables);
  write_sysconfig_data(&variables, sysconfig_out);
  const char *makefile_template =
      optional_argument_value(argc, argv, "--makefile-template");
  const char *makefile_out =
      optional_argument_value(argc, argv, "--makefile-out");
  if ((makefile_template == NULL) != (makefile_out == NULL)) {
    fail("makefile arguments must be specified together", NULL);
  }
  if (makefile_out != NULL) {
    write_makefile(&variables, makefile_template, makefile_out);
  }

  const char *sysconfig_json_out =
      optional_argument_value(argc, argv, "--sysconfig-json-out");
  if (sysconfig_json_out != NULL) {
    const char *release = argument_value(argc, argv, "--release");
    int major = integer_argument(argc, argv, "--major");
    int minor = integer_argument(argc, argv, "--minor");
    prepare_installed_variables(&variables, release, major, minor);
    write_sysconfig_json(&variables, sysconfig_json_out);
  }
  return EXIT_SUCCESS;
}
