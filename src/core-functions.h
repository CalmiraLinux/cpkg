/***************************************
 * Core functions and variables for    *
 * cpkg package manager                *
 * (C) 2021 Michail Linuxoid85 Krasnov *
 ***************************************/
#ifndef CORE_FUNCTIONS
#define CORE_FUNCTIONS
#include <iostream>
#include <fstream>
using namespace std;

/* Get current date & time */
const string getDate() {
	time_t     now = time(0);
	struct tm  tstruct;
	char       buf[80];
	tstruct = *localtime(&now);
	strftime(buf, sizeof(buf), "%Y-%m-%d %X", &tstruct);

	return buf;
}

/* Write message to log file */
void log_msg(string Function, string Message, string Status, string LogFile) {	
	ofstream log(LogFile, ios_base::app);
	
	if(!log.is_open()) {
		cout << "ОШИБКА: файл 'cpkg.log' не был открыт! Проверьте доступ к файлу журнала и повторите попытку.\n";
		exit(1);
	}
	
	log << "[ " << getDate() << " ]" << " Function '" << Function << "': " << Message << " [ " << Status << " ]\n";
	log.close();
}

/* Output log on console */
void getLog(string File) {
	string line; /* Text lines */
	
	ifstream log(File);
	if(log.is_open()) { /* If file open, then... */
		while(getline(log, line)) {
			cout << line << endl;
		}
	} else {
		cout << "ОШИБКА: файла " << File << " не существует!\n";
		log_msg("getLog", "ERROR: Попытка открытия файла не удалась! Проверьте доступ к файлу и его наличие.", "ERROR", "/var/log/cpkg.log");
		exit(1);
	}
	log.close();
}

/* Console output */
int print_msg(string Message, string Mode) {
	if(Mode == "--quiet") {
		cout << Message << endl;
		return 0;
		
	} else if(Mode == "-n") {
		cout << Message;
		return 0;
		
	} else if(Mode == "--no-quiet") {
		log_msg("print_msg", Message, "Notice", "/var/log/dbg_messages_cpkg.log");
		return 0;
		
	} else {
		log_msg("print_msg", "ERROR: uncorrect mode of 'print_message' function!", "Error", "/var/log/cpkg.log");
		return 1;
	}
}

#endif
