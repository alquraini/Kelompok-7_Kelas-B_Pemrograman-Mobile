void main() {
  // Daftar harga barang 
  Map<String, int> hargaSembako = {
    'Beras': 14000,
    'Gula Pasir': 17000,
    'Minyak Goreng': 18000,
    'Telur Ayam': 28000,
    'Susu Kental Manis': 12000,
    'Garam': 5000,
    'Gas LPG 3kg': 20000
  };

  // Daftar belanjaan 
  List<String> keranjangBelanja = [
    'Beras',
    'Beras',
    'Minyak Goreng',
    'Telur Ayam',
    'Gula Pasir'
  ];

  // Merekap jumlah barang yang sama di keranjang
  Map<String, int> rekapBelanja = {};
  for (String barang in keranjangBelanja) {
    if (rekapBelanja.containsKey(barang)) {
      rekapBelanja[barang] = rekapBelanja[barang]! + 1;
    } else {
      rekapBelanja[barang] = 1;
    }
  }

  // Memanggil fungsi-fungsi perhitungan
  int subtotal = hitungSubtotal(rekapBelanja, hargaSembako);
  int diskon = hitungDiskon(subtotal);
  int totalAkhir = subtotal - diskon;

  // Memanggil fungsi cetak untuk menampilkan hasil
  cetakStruk(rekapBelanja, hargaSembako, subtotal, diskon, totalAkhir);
}

// Fungsi 1: Menghitung subtotal 
int hitungSubtotal(Map<String, int> rekap, Map<String, int> daftarHarga) {
  int total = 0;
  rekap.forEach((barang, qty) {
    if (daftarHarga.containsKey(barang)) {
      total += daftarHarga[barang]! * qty;
    }
  });
  return total;
}

// Fungsi 2: Menentukan diskon menggunakan if/else & comparison 
int hitungDiskon(int subtotal) {
  if (subtotal >= 100000) {
    return (subtotal * 0.15).toInt(); // Diskon 15%
  } else if (subtotal >= 50000) {
    return (subtotal * 0.05).toInt(); // Diskon 5%
  } else {
    return 0; // Tidak ada diskon
  }
}

// Fungsi 3: Khusus mencetak struk agar rapi 
void cetakStruk(Map<String, int> rekap, Map<String, int> daftarHarga, int subtotal, int diskon, int totalAkhir) {
  String garisTebal = '========================================================';
  String garisPutus = '--------------------------------------------------------';

  print(garisTebal);
  print('             STRUK BELANJA / SHOPPING CART');
  print(garisTebal);

  // Mencetak rincian barang
  rekap.forEach((barang, qty) {
    if (daftarHarga.containsKey(barang)) {
      int hargaSatuan = daftarHarga[barang]!;
      int totalPerBarang = hargaSatuan * qty;
      print('- $barang');
      print('  Harga: Rp $hargaSatuan x $qty = Rp $totalPerBarang');
    }
  });

  print(garisTebal);
  print('Subtotal Belanja    : Rp $subtotal');

  // Mencetak baris diskon dengan menyesuaikan spasi
  if (subtotal >= 100000) {
    print('Diskon (15%)        : Rp $diskon');
  } else if (subtotal >= 50000) {
    print('Diskon (5%)         : Rp $diskon');
  } else {
    print('Diskon (0%)         : Rp 0');
  }

  print(garisPutus);
  print('TOTAL PEMBAYARAN    : Rp $totalAkhir');
}