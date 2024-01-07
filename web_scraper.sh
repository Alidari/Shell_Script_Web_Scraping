#!/bin/bash
#Ali Darı 20360859010
#Hisse sayisini alma işlemi
echo "Merhaba, hisse bilgileri gorme uygulamasına hos geldiniz. Uygulamamız is yatirim internet sitesi uzerindeki hisse bilgilerinizi kolaylikla onunuza sunar. Lutfen gormek istediginiz hisse sayisini giriniz."
read hisse_sayisi



#Hisse sayisina göre html tablosundan çekeceğim veri sayisini hesapliyorum (her hisse 19 satirdan oluşuyor)
veri_sayisi=$((hisse_sayisi * 19))
veri_sayisi=$((veri_sayisi + 16))

echo "Verileriniz alınıyor lütfen bekleyiniz..."

#internet sitesi, output dosyasi ve bir html dosya degiskeni
url="https://www.isyatirim.com.tr/tr-tr/analiz/hisse/Sayfalar/default.aspx"
output_file="veri.json"
html_file="html.txt"

# Web'den veriyi çekme
html=$(curl -s "$url")

# Çekilen veriyi html'e yazma (direkt degiskenden islem yapinca istedigim sonucu alamadigim icin ilk dosyaya yazdım sonra geri aldim) 
echo "$html" > "$html_file"

#html verisini geri alma
dosya=$(cat html.txt)

#cektigim html dosyası icinde hisse table'ını bulma ve table'dan sonraki veri sayisi kadar satiri alma islemi
table=$(echo "$dosya" | grep -A $veri_sayisi '<table class="dataTable hover nowrap excelexport" data-csvname="tumhisse" cellpadding="0" cellspacing="0" width="100%">') 

#table degiskeninden sed komutuyla tum etiketler siliniyor
table=$(echo "$table" | sed 's/<[^>]*>//g')
#echo "$table"

#html dosyasi guncelleniyor
echo "$table" > "html.txt"

#dosyanın icindeki gereksiz bos satirlar siliniyor ve ustune yaziliyor
sed -i -e '/^\s*$/d' -e '/^\s*#/d' html.txt

#json tarzına cevirme
dosya=$(cat html.txt)
json_metni="["

#iterasyon sayisi 13, table icindeki hisse ozellikleri 13.satirdan basliyor
it=13

#hisse sayisi kadar dongu donuyor ve iterasyon her dongude 6 artiyor cunku her hissenin 6 ozelligi var 

for ((i=1; i<=$hisse_sayisi; i++))
do
    json_metni+=$(echo "$dosya" | awk -v RS='\n\n\n' -v it="$it" 'BEGIN{print ""} {gsub(/[[:space:]]+/," "); gsub(/​/, ""); if(NF>1) printf("{\n\"Hisse\":\"%s\",\n\"Son Fiyat (TL)\":\"%s\",\n\"Değişim (%)\":\"%s\",\n\"Değişim (TL)\":\"%s\",\n\"Hacim (TL)\":\"%s\",\n\"Hacim (Adet)\":\"%s\"\n},\n",$it,$(it+1),$(it+2),$(it+3),$(it+4),$(it+5)); } END{print ""}' | sed 's/,\s*]/]/' | sed 's/},]/}]/')

    it=$((it+6))
done 

json_metni+="]"

# JSON çıktısını ekrana yazdır
echo "$json_metni"

# HTTP durumu kontrolü
if [ $? -eq 0 ]; then
    # JSON formatındaki veriyi işleme ve dosyaya yazma
    echo "$json_metni" > "$output_file"
    echo "Veri başarıyla alındı ve $output_file dosyasına yazıldı."
else
    echo "Hata: Web sitesine erişilemedi."
fi

