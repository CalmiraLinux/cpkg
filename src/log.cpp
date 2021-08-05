/******************************************
 * Program for write messages on log file *
 * (C) 2021 Michail Linuxoid85 Krasnov    *
 * <linuxoid85@gmail.com>                 *
 ******************************************/
#include <iostream>
#include <fstream>
#include "calmira-core-functions.h"
using namespace std;

/***************************
 * SYNOPSIS:               *
 * cpkg_log <MSG>          *
 ***************************/
int main(int argc, char* argv[]) {		
	if(argc < 5) {
		print_msg("ОШИБКА: недостаточное число аргументов!", "--quiet");
		log_msg("main(cpkg_log)", "ERROR: попытка запуска 'cpkg_log': ОШИБКА. Недостаточное число аргументов.", "EMERG", "/var/log/cpkg.log");
		exit(1);
	} else if(argc > 5) {
		print_msg("ОШИБКА: избыточное число аргументов!", "--quiet");
		log_msg("main(cpkg_log)", "ERROR: попытка запуска 'cpkg_log': ОШИБКА. Избыточное число аргументов.", "EMERG", "/var/log/cpkg.log");
		exit(1);
	}
	
	log_msg(argv[1], argv[2], argv[3], argv[4]);
	return 0;
}
