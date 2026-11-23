void main() {
    //Daftar Harga Barang
    Map<String, int> hargaBarang = {
        'Minyak Goreng': 25000,
        'Gas': 25000,
        'Gula': 21000,
        'Garam': 7000,
        'Beras': 12000,
        'Telur': 50000,
    };

    //Daftar Belanjaan
    List<String> belanjaan = [
        'Minyak Goreng',
        'Gas',
        'Garam',
        'Garam',
    ];

    int total = hitungTotalBelanja(belanjaan, hargaBarang);
    print('Total belanja: $total');

    int diskon = hitungDiskon(total);
    int totalAkhir = total - diskon;
    print('Diskon: $diskon');
    print('Total akhir: $totalAkhir');
}

//Total Belanja
int hitungTotalBelanja(List<String> belanjaan, Map<String, int> hargaBarang) {
    int total = 0;

    for (String barang in belanjaan) {
        if (hargaBarang.containsKey(barang)) {
            total += hargaBarang[barang]!;
        } 
    }
    return total;
}

//Case Diskon 
int hitungDiskon(int total){
    int diskon = 0;

    if (total >= 100000) {
        diskon = (total * 0.1).toInt(); // Diskon 10%
    } else if (total >= 50000) {
        diskon = (total * 0.05).toInt(); // Diskon 5%
    } else {
        diskon = 0; // Tidak ada diskon
    }
    return diskon;
}