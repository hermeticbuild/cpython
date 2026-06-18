#include <errno.h>
#include <stdio.h>
#include <string.h>

int main(int argc, char **argv) {
    char buffer[16384];
    FILE *output;

    if (argc < 3) {
        fprintf(stderr, "usage: %s OUTPUT INPUT...\n", argv[0]);
        return 2;
    }

    output = fopen(argv[1], "wb");
    if (output == NULL) {
        fprintf(stderr, "cannot open %s: %s\n", argv[1], strerror(errno));
        return 1;
    }

    for (int index = 2; index < argc; ++index) {
        FILE *input = fopen(argv[index], "rb");
        if (input == NULL) {
            fprintf(stderr, "cannot open %s: %s\n", argv[index], strerror(errno));
            fclose(output);
            return 1;
        }

        while (!feof(input)) {
            size_t count = fread(buffer, 1, sizeof(buffer), input);
            if (count != 0 && fwrite(buffer, 1, count, output) != count) {
                fprintf(stderr, "cannot write %s: %s\n", argv[1], strerror(errno));
                fclose(input);
                fclose(output);
                return 1;
            }
            if (ferror(input)) {
                fprintf(stderr, "cannot read %s: %s\n", argv[index], strerror(errno));
                fclose(input);
                fclose(output);
                return 1;
            }
        }

        if (fclose(input) != 0) {
            fprintf(stderr, "cannot close %s: %s\n", argv[index], strerror(errno));
            fclose(output);
            return 1;
        }
    }

    if (fclose(output) != 0) {
        fprintf(stderr, "cannot close %s: %s\n", argv[1], strerror(errno));
        return 1;
    }
    return 0;
}
