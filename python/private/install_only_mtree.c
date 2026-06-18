#include <ctype.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct entry {
  char *destination;
  char *mtree_line;
};

struct entries {
  struct entry *items;
  size_t length;
  size_t capacity;
};

static void *allocate(size_t size) {
  void *result = malloc(size);
  if (result == NULL) {
    fprintf(stderr, "install_only_mtree: allocation failed\n");
    exit(1);
  }
  return result;
}

static void *resize(void *value, size_t size) {
  void *result = realloc(value, size);
  if (result == NULL) {
    fprintf(stderr, "install_only_mtree: allocation failed\n");
    exit(1);
  }
  return result;
}

static char *duplicate_string(const char *value) {
  size_t size = strlen(value) + 1;
  char *result = allocate(size);
  memcpy(result, value, size);
  return result;
}

static int read_line(FILE *input, char **buffer, size_t *capacity) {
  size_t length = 0;
  int character;
  if (*buffer == NULL) {
    *capacity = 256;
    *buffer = allocate(*capacity);
  }
  while ((character = fgetc(input)) != EOF) {
    if (length + 1 >= *capacity) {
      *capacity *= 2;
      *buffer = resize(*buffer, *capacity);
    }
    if (character == '\n') {
      break;
    }
    (*buffer)[length++] = (char)character;
  }
  if (ferror(input)) {
    return -1;
  }
  if (character == EOF && length == 0) {
    return 0;
  }
  if (length > 0 && (*buffer)[length - 1] == '\r') {
    --length;
  }
  (*buffer)[length] = '\0';
  return 1;
}

static int token_equals(const char *metadata, const char *expected) {
  size_t expected_length = strlen(expected);
  const char *cursor = metadata;
  while (*cursor != '\0') {
    const char *start;
    while (isspace((unsigned char)*cursor)) {
      ++cursor;
    }
    start = cursor;
    while (*cursor != '\0' && !isspace((unsigned char)*cursor)) {
      ++cursor;
    }
    if ((size_t)(cursor - start) == expected_length &&
        memcmp(start, expected, expected_length) == 0) {
      return 1;
    }
  }
  return 0;
}

static char *token_value(const char *metadata, const char *prefix) {
  size_t prefix_length = strlen(prefix);
  const char *cursor = metadata;
  while (*cursor != '\0') {
    const char *start;
    const char *end;
    while (isspace((unsigned char)*cursor)) {
      ++cursor;
    }
    start = cursor;
    while (*cursor != '\0' && !isspace((unsigned char)*cursor)) {
      ++cursor;
    }
    end = cursor;
    if ((size_t)(end - start) > prefix_length &&
        memcmp(start, prefix, prefix_length) == 0) {
      size_t value_length = (size_t)(end - start) - prefix_length;
      char *value = allocate(value_length + 1);
      memcpy(value, start + prefix_length, value_length);
      value[value_length] = '\0';
      return value;
    }
  }
  return NULL;
}

static int ends_with(const char *value, const char *suffix) {
  size_t value_length = strlen(value);
  size_t suffix_length = strlen(suffix);
  return value_length >= suffix_length &&
         strcmp(value + value_length - suffix_length, suffix) == 0;
}

static int is_executable(const char *destination) {
  static const char *const suffixes[] = {".dll", ".dylib", ".exe", ".pyd",
                                         ".so"};
  size_t index;
  if (strncmp(destination, "python/bin/", strlen("python/bin/")) == 0) {
    return 1;
  }
  for (index = 0; index < sizeof(suffixes) / sizeof(suffixes[0]); ++index) {
    if (ends_with(destination, suffixes[index])) {
      return 1;
    }
  }
  return 0;
}

static void append_entry(struct entries *entries, char *destination,
                         char *mtree_line) {
  if (entries->length == entries->capacity) {
    entries->capacity = entries->capacity == 0 ? 256 : entries->capacity * 2;
    entries->items =
        resize(entries->items, entries->capacity * sizeof(entries->items[0]));
  }
  entries->items[entries->length].destination = destination;
  entries->items[entries->length].mtree_line = mtree_line;
  ++entries->length;
}

static int compare_entries(const void *left_value, const void *right_value) {
  const struct entry *left = left_value;
  const struct entry *right = right_value;
  return strcmp(left->destination, right->destination);
}

static char *file_mtree_line(const char *destination, const char *content) {
  const char *mode = is_executable(destination) ? "0755" : "0644";
  size_t capacity = strlen(destination) + strlen(content) + 160;
  char *result = allocate(capacity);
  int length = snprintf(result, capacity,
                        "%s uid=0 gid=0 uname=root gname=root time=1704067200 "
                        "mode=%s type=file nlink=1 content=%s",
                        destination, mode, content);
  if (length < 0 || (size_t)length >= capacity) {
    fprintf(stderr, "install_only_mtree: failed to format %s\n", destination);
    exit(1);
  }
  return result;
}

static char *link_mtree_line(const char *destination, const char *target) {
  size_t capacity = strlen(destination) + strlen(target) + 160;
  char *result = allocate(capacity);
  int length = snprintf(result, capacity,
                        "%s uid=0 gid=0 uname=root gname=root time=1704067200 "
                        "mode=0777 type=link nlink=1 link=%s",
                        destination, target);
  if (length < 0 || (size_t)length >= capacity) {
    fprintf(stderr, "install_only_mtree: failed to format %s\n", destination);
    exit(1);
  }
  return result;
}

static int valid_version(const char *version) {
  const unsigned char *cursor = (const unsigned char *)version;
  if (*cursor == '\0') {
    return 0;
  }
  for (; *cursor != '\0'; ++cursor) {
    if (!isdigit(*cursor) && *cursor != '.') {
      return 0;
    }
  }
  return 1;
}

int main(int argc, char **argv) {
  const char *input_path;
  const char *output_path;
  const char *version;
  int add_python_symlinks;
  FILE *input;
  FILE *output;
  char *line = NULL;
  size_t line_capacity = 0;
  int read_result;
  struct entries entries = {0};
  size_t index;
  char *interpreter = NULL;
  int found_interpreter = 0;

  if (argc != 4 && argc != 5) {
    fprintf(stderr, "usage: install_only_mtree INPUT OUTPUT VERSION "
                    "[--add-python-symlinks]\n");
    return 2;
  }
  input_path = argv[1];
  output_path = argv[2];
  version = argv[3];
  add_python_symlinks = argc == 5;
  if (!valid_version(version) ||
      (add_python_symlinks && strcmp(argv[4], "--add-python-symlinks") != 0)) {
    fprintf(stderr, "install_only_mtree: invalid arguments\n");
    return 2;
  }

  input = fopen(input_path, "rb");
  if (input == NULL) {
    fprintf(stderr, "install_only_mtree: cannot open %s: %s\n", input_path,
            strerror(errno));
    return 1;
  }
  while ((read_result = read_line(input, &line, &line_capacity)) > 0) {
    char *metadata;
    char *cursor = line;
    char *content;
    char *destination;
    size_t destination_size;
    while (*cursor != '\0' && !isspace((unsigned char)*cursor)) {
      ++cursor;
    }
    if (*cursor == '\0') {
      fprintf(stderr, "install_only_mtree: malformed mtree line: %s\n", line);
      fclose(input);
      return 1;
    }
    *cursor++ = '\0';
    metadata = cursor;
    if (strncmp(line, "install/", strlen("install/")) != 0) {
      fprintf(stderr, "install_only_mtree: path is outside install/: %s\n",
              line);
      fclose(input);
      return 1;
    }
    if (token_equals(metadata, "type=dir")) {
      continue;
    }
    if (!token_equals(metadata, "type=file")) {
      fprintf(stderr, "install_only_mtree: unsupported entry type: %s\n", line);
      fclose(input);
      return 1;
    }
    content = token_value(metadata, "content=");
    if (content == NULL) {
      fprintf(stderr, "install_only_mtree: file has no content: %s\n", line);
      fclose(input);
      return 1;
    }
    destination_size =
        strlen("python/") + strlen(line + strlen("install/")) + 1;
    destination = allocate(destination_size);
    snprintf(destination, destination_size, "python/%s",
             line + strlen("install/"));
    append_entry(&entries, destination, file_mtree_line(destination, content));
    free(content);
  }
  if (read_result < 0) {
    fprintf(stderr, "install_only_mtree: cannot read %s: %s\n", input_path,
            strerror(errno));
    fclose(input);
    return 1;
  }
  if (fclose(input) != 0) {
    fprintf(stderr, "install_only_mtree: cannot close %s: %s\n", input_path,
            strerror(errno));
    return 1;
  }
  free(line);

  if (add_python_symlinks) {
    size_t interpreter_size = strlen("python/bin/python") + strlen(version) + 1;
    interpreter = allocate(interpreter_size);
    snprintf(interpreter, interpreter_size, "python/bin/python%s", version);
    for (index = 0; index < entries.length; ++index) {
      if (strcmp(entries.items[index].destination, interpreter) == 0) {
        found_interpreter = 1;
        break;
      }
    }
    if (!found_interpreter) {
      fprintf(stderr, "install_only_mtree: missing %s\n", interpreter);
      return 1;
    }
    append_entry(&entries, duplicate_string("python/bin/python"),
                 link_mtree_line("python/bin/python",
                                 interpreter + strlen("python/bin/")));
    append_entry(&entries, duplicate_string("python/bin/python3"),
                 link_mtree_line("python/bin/python3",
                                 interpreter + strlen("python/bin/")));
    free(interpreter);
  }

  qsort(entries.items, entries.length, sizeof(entries.items[0]),
        compare_entries);
  for (index = 1; index < entries.length; ++index) {
    if (strcmp(entries.items[index - 1].destination,
               entries.items[index].destination) == 0) {
      fprintf(stderr, "install_only_mtree: duplicate destination %s\n",
              entries.items[index].destination);
      return 1;
    }
  }

  output = fopen(output_path, "wb");
  if (output == NULL) {
    fprintf(stderr, "install_only_mtree: cannot open %s: %s\n", output_path,
            strerror(errno));
    return 1;
  }
  for (index = 0; index < entries.length; ++index) {
    if (fprintf(output, "%s\n", entries.items[index].mtree_line) < 0) {
      fprintf(stderr, "install_only_mtree: cannot write %s: %s\n", output_path,
              strerror(errno));
      fclose(output);
      remove(output_path);
      return 1;
    }
  }
  if (fclose(output) != 0) {
    fprintf(stderr, "install_only_mtree: cannot close %s: %s\n", output_path,
            strerror(errno));
    remove(output_path);
    return 1;
  }

  for (index = 0; index < entries.length; ++index) {
    free(entries.items[index].destination);
    free(entries.items[index].mtree_line);
  }
  free(entries.items);
  return 0;
}
