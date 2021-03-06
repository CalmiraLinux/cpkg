# CPkg - Calmira Packages

## Введение

`cpkg` - пакетный менеджер для Calmira GNU/Linux. Он написан с нуля на `bash` и предоставляет базовые функции для установки и удаления пакетов.

На данный момент в Calmira используется система портов вместо установки бинарных пакетов. Используйте cpkg только для установки крупных бинарных пакетов, для всего остального советуем использовать порты.

## Синтаксис

Установка ПО:
```bash
cpkg install $PACKAGE.txz
# или
cpkg -i $PACKAGE.txz
```

> cpkg не скачивает пакеты при установке.

Во время установки и удаления пакета у вас будет отображены его зависимости. Если они не установлены (или необходимые не удалены), то введите `n` и установите/удалите то, что описано там.

Скачивание пакета:

```bash
cpkg download $PACKAGE
# или
cpkg -d $PACKAGE
```

Удаление ПО:
```bash
cpkg remove $PACKAGE
# или
cpkg -r $PACKAGE
```

## Дополнительные опции
О работе с дополнительными опциями написано в инструкции:
```bash
cpkg help
```

## Создание бинарного пакета для `cpkg`
Пакет для `cpkg` представляет собой tar архив, сжатый методом `xz`. В архиве находится директория PKG, в которой находятся файлы `config.sh`, `preinst.sh` (опционально), `postinst.sh` (опционально), а так же директория `pkg`, в которой находится сам пакет. Дерево каталогов пакета должно совпадать с деревом каталогов операционной системы.

**Назначение файлов и директорий:**
* `PKG` - в этой директории находятся сам пакет и файлы описания, а так же файлы пред- и послеустановочных настроек.
* `PKG/pkg` - директория с пакетом
* `PKG/config.sh` - описание пакета
* `PKG/preinst.sh` - скрипт, выполняющийся до установки пакета. Может быть полезен для настройки системы или окружения перед установкой пакета. Наличие этого файла **опционально**.
* `PKG/postinst.sh` - скрипт, выполняющийся после установки пакета. Может быть полезен для настройки пакета. Наличие этого файла **опционально**.
* `PKG/preremove.sh` - скрипт, выполняющийся до удаления пакета. Может быть полезен для настройки системы или окружения.
* `PKG/postremove.sh` - скрипт, выполняющийся после удаления пакета. Может быть полезен для окончательной настройки системы/окружения, а так же удаления некоторых конфигурационных (и других) файлов, не вошедших в список файлов пакета.
* `PKG/metadata.xz` - в данном архиве содержится информация о совместимости пакета с дистрибутивом Calmira.

Тогда дерево каталогов пакета будет примерно таким:
```
|--- some_package.txz
    |--- PKG
        |--- config.sh
        |--- {post,pre}inst.sh
        |--- {post,pre}remove.sh
        |--- metadata.xz
        |--- pkg
            |--- usr
            |--- etc
            |--- var
            |--- ...
```

В случае, если это пакет с исходным кодом (port-пакет), в директории `PKG` наличие файла `port.sh` **обязательно**. В нём описываются инструкции по сборке и установке пакета.

Наличие шебанга обязательно:
```bash
#!/bin/bash
```

Пример:
```bash
#!/bin/bash

cd /var/cache/cpkg/archives	# Переход в рабочую директорию
wget https://www.some.site/some_package.tar.gz	# Скачивание пакета some_package.tar.gz с сайта https://www.some.site
tar -xvf some_package.tar.gz	# Распаковка пакета с исходным кодом

cd some_package
./configure --prefix=/usr \
	--bindir=/usr/bin \
	--sysconfdir=/etc	# Конфигурирование пакета
make		# Сборка
make install	# Установка
```

### Строение файла `config.sh`
В этом файле описывается сам пакет. В нём указывается имя пакета, версия, мейнтейнер, описание и файлы пакета.
Пример такого файла:
```bash
NAME=some_package
VERSION=1.0
MAINTAINER="Linuxoid85 <linuxoid85@gmail.com>"
REQ_DEPS="bash"
OPT_DEPS="coreutils"
TEST_DEPS="expect"
BEF_DEPS="cpkg"
CON_DEPS="wget openssl make-ca"
PRIORITY=user
DESCRIPTION="Some package for test cpkg package manager"
FILES="/usr/bin/{some_pkg,test_cpkg} /usr/share/some_pkg/"
```

**Описание переменных:**
* `NAME` - имя пакета
* `VERSION` - версия пакета/программы
* `MAINTAINER` - сборщик (сопровождающий) пакета
* `REQ_DEPS` - необходимые для работы пакета зависимости
* `OPT_DEPS` - опциональные зависимости
* `TEST_DEPS` - необходимые для тестирования пакета зависимости (указывать только в port-пакетах)
* `BEF_DEPS` - какие пакеты требуют, чтобы указанный пакет был собран и установлен до их сборки и установки.
* `CON_DEPS` - зависимости, с которыми конфликтует данный пакет
* `PRIORITY` - приоритет пакета
* `DESCRIPTION` - описание пакета
* `FILES` - все файлы пакета.

Если в одной директории (чаще всего это `/bin`, `/usr/bin`, `/etc` и пр.) несколько файлов из пакета, то нет смысла дублировать пути до этих файлов. Проще объединить их в массив. К примеру, есть директория `/usr/bin`, в которую устанавливаются файлы `some_pkg` и `test_cpkg`. В строке `FILES="..."` они объединены в массив `/usr/bin/{some_pkg,test_cpkg}`. То есть, файлы перечисляются в фигурных скобках {}.

Так же, все отдельные файлы разделяются между собой пробелами.

В версии cpkg 1.0pa4 была добавлена функция просмотра зависимостей пакета (при установке, удалении и просмотра информации о пакете).

Типов зависимостей несколько:

| Наименование | Объяснение | В какой строке отображается при установке или удалении исходного пакета |
|--------------|------------|-------------------------------------------------------------------------|
| `REQ_DEPS`   | необходимые зависимости. Если вы устанавливаете бинарный пакет, то необходимые зависимости можно установить после, но если вы ставите port-пакет, то поставьте сначала необходимые зависимости, а только потом пакет. | `Необходимые:` |
| `OPT_DEPS` | опциональные зависимости. Устанавливать их не обязательно, они лишь служат для добавления определённого функционала. Если вы ставите бинарный пакет, то не важен порядок действий: вы можете установить их как до установки исходного пакета, так и после, если этих зависимостей нет в пункте `BEF_DEPS`. Но в случае port-пакета всё намного строже - опциональные пакеты должны быть установлены ДО установки исходного пакета. | `Опциональные:` |
| `TEST_DEPS` | зависимости, необходимые для тестирования пакета (распространяется только на port-пакеты). Эти зависимости должны быть установлены ДО установки исходного пакета. | `Для тестирования:` |
| `CON_DEPS` | зависимости, которые конфликтуют с данным пакетом. Их желательно удалить. | `Конфликтует с:` |
| `BEF_DEPS` | необязательные зависимости, определяющие, что указанный пакет должен быть собран ДО установки/сборки тех зависимостей. Применимо к port-пакетам. | `Установлен перед ними:` |

Помимо этого, есть приоритет пакета - `PRIORITY`. Только два значения: `system`, если пакет системный и `user` - если пользовательский. Т.е., в первую группу входят все пакеты, которые обеспечивают корректную работу МИНИМАЛЬНОЙ системы. Системные пакеты удалить нельзя. Их можно лишь обновлять до новой версии и просматривать информацию о них. А с пользовательскими пакетами (приоритет `user`) можно делать всё, что угодно.

> Настоятельно рекомендуем использовать пользовательский (`user`) пакета! Все системные пакеты собираются одним мейнтейнером для поддержания работоспособности системы. Как правило, большинство пакетов от сторонних сборщиком с приоритетом `system` не только не являются системными, но и при удалении этих пакетов в системе не произойдёт ничего.

### Строение файлов `post-` и `preinst.sh`
Как было сказано выше, первый файл выполняется до установки пакета, а второй - после. Они нужны для настройки окружения или системы (до установки) и пакета (после установки). Эти файлы - BASH-скрипты.

> Шебанг `#!/bin/bash` обязателен.

В этих скриптах доступны все команды `bash`.

## Установка cpkg на Calmira Linux

В репозитории ПО для Calmira GNU/Linux, зачастую, не самая последняя версия `cpkg`. Для того, чтобы установить самую последнюю, нужно скачать её с этого репа и установить. Принцип действий таков:
* Скачивание пакета
* Установка/обновление
* Проверка на работоспособность.

Например, скачивание последней тестовой версии pa2:
```bash
# Скачивание пакета. Заметьте, что скачивается он из раздела Releases (GitHub).
wget https://github.com/Linuxoid85/cpkg/releases/download/1.0.pa2/cpkg.txz
# Установка или обновление
cpkg -i cpkg.txz
# Обновление списка пакетов cpkg
cpkg update
```

Заметьте, что все релизы скачиваются [отсюда](https://github.com/Linuxoid85/cpkg/releases). Об этом была пометка выше.

В том случае, если вы по каким-то причинам удалили `cpkg`, либо же он находится в неработоспособном состоянии, то выполните:
```bash
# Если cpkg установлен, но находится в неработоспособном состоянии, удалите его (если он не установлен, то и удалять не надо):
rm -rvf /usr/bin/cpkg /usr/lib/cpkg /etc/cpkg/{settings,pkg.list}
# Скачивание актуальной версии:
wget https://github.com/Linuxoid85/cpkg/releases/download/1.0.pa2/cpkg.txz
# Распаковка:
tar -xf cpkg.txz
# Установка:
cd PKG/pkg
cp -rv * /
```

Так как пакет для cpkg - tar архив, сжатый методом `xz`, то никаких утилит доустанавливать не нужно - всё уже доступно в системе.

Если же вы хотите установить экспериментальную версию с git, то можете клонировать этот репозиторий и поставить. Однако, пакеты с экспериментальной версией не формируются, сделайте это самостоятельно. Порядок действий таков:
* Клонируйте этот репозиторий
* Перейдите в директорию с пакетом
* Сгенерируйте пакет
* Установите его

> Настоятельно рекомендуется генерировать, а затем устанавливать *пакет*, но не копировать папки `usr` и `etc` экспериментальной версии. Помимо этого, не рекомендуется вообще ставить экспериментальную сборку, так как это может сломать вашу систему.

```bash
# Клонирование репозитория
git clone https://github.com/Linuxoid85/cpkg
cd cpkg/cpkg
# Генерация пакета
chmod +x makepkg.sh
./makepkg.sh
# Установка пакета
cpkg -i cpkg-$VERSION.txz
```

> Замените `$VERSION` на версию пакета, например, на 1.0pa3. Тогда имя пакета будет таким: `cpkg-1.0pa3.txz`

## Зависимости
* `bash`
* `coreutils`
* `exa`
* `calmira scripts` (опционально; в разработке)

***
На этом руководство по использованию `cpkg` окончено.

Удачи!
