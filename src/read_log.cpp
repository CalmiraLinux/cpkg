/*******************************************
 * Program for read messages from log file *
 * (C) 2021 Michail Linuxoid85 Krasnov     *
 * <linuxoid85@gmail.com>                  *
 *******************************************/
#include <iostream>
#include <fstream>
#include "calmira-core-functions.h"
using namespace std;

/***************************
 * SYNOPSIS:               *
 * cpkg_log_read <MSG>     *
 ***************************/
int main(int argc, char* argv[]) {		
	if(argc < 2) {
		print_msg("ОШИБКА: недостаточное число аргументов!", "--quiet");
		log_msg("main(cpkg_log_read)", "ERROR: попытка запуска 'cpkg_log_read': ОШИБКА. Недостаточное число аргументов.", "EMERG", "/var/log/cpkg.log");
		exit(1);
	} else if(argc > 2) {
		print_msg("ОШИБКА: избыточное число аргументов!", "--quiet");
		log_msg("main(cpkg_log_read)", "ERROR: попытка запуска 'cpkg_log_read': ОШИБКА. Избыточное число аргументов.", "EMERG", "/var/log/cpkg.log");
		exit(1);
	}
	
	getLog(argv[1]);
	return 0;
}
