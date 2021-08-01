#ifndef LOG_FUNCTIONS
#define LOG_FUNCTIONS
#include <iostream>
#include <fstream>
using namespace std;

/* Get current date & time */
const string _getDate() {
	time_t     now = time(0);
	struct tm  tstruct;
	char       buf[80];
	tstruct = *localtime(&now);
	strftime(buf, sizeof(buf), "%Y-%m-%d %X", &tstruct);

	return buf;
}

void log_msg(string Function, string Message, string Status);

/* Output log on console */
void getLog(string File) {
	string line;
	
	ifstream log(File);
	if(log.is_open()) {
		while(getline(log, line)) {
			cout << line << endl;
		}
	} else {
		cout << "ОШИБКА: файла " << File << " не существует!\n";
		log_msg("getLog", "Попытка открытия файла не удалась!", "ERROR");
		exit(1);
	}
	log.close();
}

/* Write message to log file */
void log_msg(string Function, string Message, string Status) {	
	ofstream log("/var/log/cpkg.log", ios_base::app);
	
	if(!log.is_open()) {
		cout << "ОШИБКА: файл 'cpkg.log' не был открыт!\n";
		exit(1);
	}
	
	log << "[ " << _getDate() << " ]" << " Function '" << Function << "': " << Message << " [ " << Status << " ]\n";
	log.close();
}

#endif
