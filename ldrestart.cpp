//
//  main.cpp
//  ldrestart
//
//  Created by Lakr Aream on 3/20/21.
//

// MARK: - GPLv3 License

/* Cydia - iPhone UIKit Front-End for Debian APT
 * Copyright (C) 2008-2015  Jay Freeman (saurik)
 */

/*
 * Cydia is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published
 * by the Free Software Foundation, either version 3 of the License,
 * or (at your option) any later version.
 *
 * Cydia is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Cydia.  If not, see <http://www.gnu.org/licenses/>.
 */


/*
 * usage: g++ main.cpp -o ldrestart
 */

// MARK: -

#include <cstdio>
#include <cstdlib>
#include <errno.h>
#include <signal.h>
#include <sysexits.h>
#include <unistd.h>
#include <launch.h>
#include <sys/stat.h>
#include <iostream>

void process(launch_data_t value, const char *name, void *baton) {
    if (launch_data_get_type(value) != LAUNCH_DATA_DICTIONARY)
        return;

    auto integer(launch_data_dict_lookup(value, LAUNCH_JOBKEY_PID));
    if (integer == NULL || launch_data_get_type(integer) != LAUNCH_DATA_INTEGER)
        return;
    
    auto string(launch_data_dict_lookup(value, LAUNCH_JOBKEY_LABEL));
    if (string == NULL || launch_data_get_type(string) != LAUNCH_DATA_STRING)
        return;
    auto label(launch_data_get_string(string));
    
    auto pid(launch_data_get_integer(integer));
    if (kill(pid, 0) == -1)
        return;

    auto stop(launch_data_alloc(LAUNCH_DATA_DICTIONARY));
    launch_data_dict_insert(stop, string, LAUNCH_KEY_STOPJOB);

    auto result(launch_msg(stop));
    launch_data_free(stop);
    if (result == NULL)
        return;

    if (launch_data_get_type(result) != LAUNCH_DATA_ERRNO)
        fprintf(stderr, "%s\n", label);
    else if (auto number = launch_data_get_errno(result))
        fprintf(stderr, "%s: %s\n", label, strerror(number));

    launch_data_free(result);
}

int initial_restart() {
    auto request(launch_data_new_string(LAUNCH_KEY_GETJOBS));
    auto response(launch_msg(request));
    launch_data_free(request);

    if (response == NULL)
        return EX_UNAVAILABLE;
    if (launch_data_get_type(response) != LAUNCH_DATA_DICTIONARY)
        return EX_SOFTWARE;

    launch_data_dict_iterate(response, &process, NULL);
    return EX_OK;
}

int delayed_restart() {
    printf("failed to kiss launchd, restart delayed for 5 seconds\n");
    sleep(1);
    printf("failed to kiss launchd, restart delayed for 4 seconds\n");
    sleep(1);
    printf("failed to kiss launchd, restart delayed for 3 seconds\n");
    sleep(1);
    printf("failed to kiss launchd, restart delayed for 2 seconds\n");
    sleep(1);
    printf("failed to kiss launchd, restart delayed for 1 seconds\n");
    sleep(1);
    return initial_restart();
}

int main(int argc, char *argv[]) {
    
    int orig_pid = getpid();
    pid_t f1 = fork();
    if (f1 < 0) { return delayed_restart(); }
    if (f1 == 0) {
        int child_one = getpid();
        pid_t f2 = fork();
        if (f2 < 0) { return delayed_restart(); }
        if (f2 == 0) {
            int new_pid = getpid();
            int ppid = getppid();
            printf("waiting parent process to exit\n");
            sleep(1);
            printf("\nsuccessfully hooked to launchd, planing safe restart...\n");
            printf("pid %d -> %d -> %d, child of %d\n", orig_pid, child_one, new_pid, ppid);
            return initial_restart();
        }
    }
    
    return 0;
}

