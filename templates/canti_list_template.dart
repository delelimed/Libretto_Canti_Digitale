class Canto {
  final int numero;
  final String titolo;
  final String momento1;
  final String? momento2;
  final String? momento3;
  final int inizioPagina;
  final int finePagina;

  const Canto({
    required this.numero,
    required this.titolo,
    required this.momento1,
    this.momento2,
    this.momento3,
    required this.inizioPagina,
    required this.finePagina,
  });
}


final List<Canto> canti = [
  Canto(numero: 00, titolo: "Titolo", momento1: "UNKNOWN1", inizioPagina: 0, finePagina: 0),
  Canto(numero: 00, titolo: "Titolo", momento1: "UNKNOWN1", momento2: "UNKNOWN2", inizioPagina: 0, finePagina: 0), 
  Canto(numero: 00, titolo: "Titolo", momento1: "UNKNOWN1", inizioPagina: 0, finePagina: 0),
];