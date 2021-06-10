# Инструкция по установке

Загрузите пакет cpkg (`git clone https://github.com/Linuxoid85/cpkg`) и переместите содержимое директории `cpkg` в корень:

```bash
cp -rv cpkg/* /
```

В том случае, если выполняется обновление до последней версии программы, загрузите последнюю версию пакета (`wget https://github.com/Linuxoid85/cpkg/releases/download/1.0.pa1/cpkg.txz) и установите её:

```bash
cpkg -i cpkg.txz
```
