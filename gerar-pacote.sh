#!/bin/bash

DEMOISELLE_HOME=/opt/demoiselle
DEMOISELLE_DEB=/var/packages
DEMOISELLE_TMP=/tmp/demoiselle-packages

if [ $# -ne 1 ]; then
	echo "Uso: $0 <nome-do-pacote>"
	echo "Exemplo: $0 demoiselle-eclipse-3.5"
	echo
	exit 1
fi

pacote="$( echo $1 | tr -d '/' )"

if [ ! -d $1 ]; then
	echo "Pacote inexistente! Nome: $pacote"
	echo
	exit 2
fi

echo "Gerando pacote $pacote..."

sources="./$pacote"
control="$sources/DEBIAN/control"
tempctl="/tmp/$$.control"

arch=$( awk '/^Architecture:/{print$2}' $control )

version=$( awk '/^Version/{print$2}' $control )
release=$( echo $version | sed 's/^.*\-\([0-9]\+\)$/\1/' )

# incrementar contador da release
if [ "$release" == "" ]; then
	release=0
else
	let release++
fi
nextver=$( echo -n $version | sed 's/^\(.*\)\-\([0-9]\+\)$/\1/'; echo "-$release" )
echo "Versão atual: $version, Próxima versão: $nextver"

# calcular espaço em disco ocupado pelo pacote
instsize=`du -sL $sources | cut -f1`

# atualizar versão e tamanho no DEBIAN/control
sed -e "s/^Version: .*$/Version: $nextver/" \
	-e "s/^Installed-Size: .*$/Installed-Size: $instsize/" \
	$control > $tempctl
mv $tempctl $control

# copiar arquivos para diretório temporário
destin="${DEMOISELLE_TMP}/${pacote}"
rm -rf $destin
mkdir -p $destin
cp -RL ${sources}/* $destin

# executar instruções de preparação
prepare="$destin/DEBIAN/prepare"
if [ -f $prepare ]; then
	echo "Executando preparação final..."
	(cd $destin; bash $prepare)
	rm -f $prepare
fi

# gerar pacote Debian
packfile="${pacote}_${nextver}_${arch}.deb"
dpkg-deb --build $destin ${DEMOISELLE_DEB}/$packfile

# excluir arquivos temporários
rm -rf $destin

exit 0
