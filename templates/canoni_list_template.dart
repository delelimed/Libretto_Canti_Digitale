class Canone {
  final String numero;
  final String titolo;
  final String momento1;
  final int inizioPagina;
  final int finePagina;

  const Canone({
    required this.numero,
    required this.titolo,
    required this.momento1,
    required this.inizioPagina,
    required this.finePagina,
  });
}

final List<Canone> canoni = [
  Canone(numero: "Cxx", titolo: "Titolo", momento1: "Canone", inizioPagina: 00, finePagina: 00),
  Canone(numero: "Cxx", titolo: "Titolo", momento1: "Canone", inizioPagina: 00, finePagina: 00),
  
];
