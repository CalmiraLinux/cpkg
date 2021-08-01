#include <iostream>
#include <fstream>
#include "core-functions.h"
using namespace std;

int main(int argc, char* argv[]) {
	if(argc != 5) {
		print_msg("ОШИБКА: неверное число аргументов командной строки!\n", "--quiet");
		log_msg("main(/usr/bin/cpkg_log)", "ERROR: Попытка запуска 'main': ОШИБКА. Неверное число аргументов.", "EMERG", "/var/log/cpkg.log");
		exit(1);
	}
	
	log_msg(argv[1], argv[2], argv[3], argv[4]);
	return 0;
}
