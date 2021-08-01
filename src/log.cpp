#include <iostream>
#include <fstream>
#include "log_functions.h"
using namespace std;

int main(int argc, char* argv[]) {
	if(argc != 4) {
		cout << "ОШИБКА: неверное число аргументов командной строки!\n";
		log_msg("main(/usr/bin/log)", "Попытка запуска 'log': ОШИБКА. Неверное число аргументов.", "EMERG");
		exit(1);
	}
	
	log_msg(argv[1], argv[2], argv[3]);
	return 0;
}
