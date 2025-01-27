#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <syslog.h>

int main(int argc, char *argv[]) {
    // Open syslog for logging
    openlog("writer", LOG_PID | LOG_CONS, LOG_USER);

    // Check for correct number of arguments
    if (argc != 3) {
        syslog(LOG_ERR, "Usage: %s <file> <string>", argv[0]);
        fprintf(stderr, "Usage: %s <file> <string>\n", argv[0]);
        closelog();
        return EXIT_FAILURE;
    }

    const char *file_path = argv[1];
    const char *string_to_write = argv[2];

    // Open the file for writing
    FILE *file = fopen(file_path, "w");
    if (file == NULL) {
        syslog(LOG_ERR, "Failed to open file %s: %s", file_path, strerror(errno));
        perror("Error");
        closelog();
        return EXIT_FAILURE;
    }

    // Write the string to the file
    if (fprintf(file, "%s", string_to_write) < 0) {
        syslog(LOG_ERR, "Failed to write to file %s: %s", file_path, strerror(errno));
        perror("Error");
        fclose(file);
        closelog();
        return EXIT_FAILURE;
    }

    // Log the successful write operation
    syslog(LOG_DEBUG, "Writing '%s' to '%s'", string_to_write, file_path);

    // Close the file
    if (fclose(file) != 0) {
        syslog(LOG_ERR, "Failed to close file %s: %s", file_path, strerror(errno));
        perror("Error");
        closelog();
        return EXIT_FAILURE;
    }

    // Close syslog
    closelog();
    return EXIT_SUCCESS;
}