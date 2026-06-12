import 'package:flutter/material.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class MockPolicy {
  const MockPolicy({
    required this.id,
    required this.ramo,
    required this.aseguradora,
    required this.numero,
    required this.estado,
    required this.suma,
    required this.prima,
    required this.period,
    required this.proxPago,
    required this.deducible,
    this.dias,
  });

  final String id;
  final String ramo;
  final String aseguradora;
  final String numero;
  final String estado;
  final String suma;
  final String prima;
  final String period;
  final String proxPago;
  final String deducible;
  final int? dias;
}

class MockNote {
  const MockNote({required this.tipo, required this.t, required this.src});
  final String tipo; // doc | whatsapp | wave | image | note
  final String t;
  final String src;
}

class MockClient {
  const MockClient({
    required this.id,
    required this.nombre,
    required this.inicial,
    required this.color,
    required this.ocupacion,
    required this.edad,
    required this.ciudad,
    required this.tel,
    required this.email,
    required this.desde,
    required this.diasSinContacto,
    required this.polizas,
    required this.notas,
  });

  final String id;
  final String nombre;
  final String inicial;
  final Color color;
  final String ocupacion;
  final int edad;
  final String ciudad;
  final String tel;
  final String email;
  final String desde;
  final int diasSinContacto;
  final List<MockPolicy> polizas;
  final List<MockNote> notas;
}



class MockMessage {
  const MockMessage({
    required this.id,
    required this.role,
    required this.text,
    this.big,
    this.card,
    this.bullets,
  });

  final String id;
  final String role; // user | ai
  final String text;
  final String? big;
  final MockMsgCard? card;
  final List<List<String>>? bullets;
}

class MockMsgCard {
  const MockMsgCard({required this.ramo, required this.numero, required this.rows});
  final String ramo;
  final String numero;
  final List<List<String>> rows;
}

// ── Data ─────────────────────────────────────────────────────────────────────

final mockClients = <MockClient>[
  MockClient(
    id: 'mariana',
    nombre: 'Mariana Torres',
    inicial: 'MT',
    color: const Color(0xFF007AC0),
    ocupacion: 'Arquitecta',
    edad: 34,
    ciudad: 'CDMX',
    tel: '+52 55 1234 5678',
    email: 'mariana.torres@email.com',
    desde: 'Cliente 2019',
    diasSinContacto: 18,
    polizas: [
      MockPolicy(
        id: 'p1', ramo: 'Auto', aseguradora: 'GNP', numero: 'AUT-552190',
        estado: 'Por renovar', dias: 14,
        suma: '\$450,000', prima: '\$11,300', period: 'Anual',
        proxPago: '4 jun 2026', deducible: '\$22,500',
      ),
      MockPolicy(
        id: 'p2', ramo: 'Gastos Médicos', aseguradora: 'AXA', numero: 'GMM-881934',
        estado: 'Vigente',
        suma: '\$3,000,000', prima: '\$8,400', period: 'Semestral',
        proxPago: '12 ago 2026', deducible: '\$15,000',
      ),
    ],
    notas: [
      MockNote(tipo: 'whatsapp', t: 'Preguntó sobre cobertura de accesorios en auto.', src: 'WhatsApp · 28 may'),
      MockNote(tipo: 'note', t: 'Interesada en seguro de vida para sus hijos.', src: 'Nota manual · 15 abr'),
    ],
  ),
  MockClient(
    id: 'javier',
    nombre: 'Javier Mendoza',
    inicial: 'JM',
    color: const Color(0xFF0E7C42),
    ocupacion: 'Médico',
    edad: 52,
    ciudad: 'Monterrey',
    tel: '+52 81 9876 5432',
    email: 'javier.mendoza@hospital.mx',
    desde: 'Cliente 2017',
    diasSinContacto: 5,
    polizas: [
      MockPolicy(
        id: 'p3', ramo: 'Vida', aseguradora: 'Metlife', numero: 'VID-231099',
        estado: 'Vigente',
        suma: '\$5,000,000', prima: '\$24,000', period: 'Anual',
        proxPago: '1 ene 2027', deducible: '—',
      ),
      MockPolicy(
        id: 'p4', ramo: 'Gastos Médicos', aseguradora: 'GNP', numero: 'GMM-990341',
        estado: 'Pago próximo', dias: 9,
        suma: '\$10,000,000', prima: '\$31,500', period: 'Anual',
        proxPago: '10 jun 2026', deducible: '\$30,000',
      ),
    ],
    notas: [
      MockNote(tipo: 'wave', t: 'Llamada — consulta sobre cobertura en el extranjero.', src: 'Audio · 2 jun'),
      MockNote(tipo: 'doc', t: 'Póliza GMM renovada correctamente.', src: 'PDF · 1 ene 2026'),
    ],
  ),
  MockClient(
    id: 'lucia',
    nombre: 'Lucía García',
    inicial: 'LG',
    color: const Color(0xFFB9791A),
    ocupacion: 'Empresaria',
    edad: 45,
    ciudad: 'Guadalajara',
    tel: '+52 33 5555 1234',
    email: 'lucia@grupogc.mx',
    desde: 'Prospecto',
    diasSinContacto: 22,
    polizas: [],
    notas: [
      MockNote(tipo: 'note', t: 'Interesada en seguro de grupo para empleados.', src: 'Nota · 20 may'),
    ],
  ),
  MockClient(
    id: 'carlos',
    nombre: 'Carlos Reyes',
    inicial: 'CR',
    color: const Color(0xFF7A4FD0),
    ocupacion: 'Contador',
    edad: 38,
    ciudad: 'CDMX',
    tel: '+52 55 8888 9012',
    email: 'carlos.reyes@cfdi.mx',
    desde: 'Cliente 2021',
    diasSinContacto: 3,
    polizas: [
      MockPolicy(
        id: 'p5', ramo: 'Auto', aseguradora: 'Qualitas', numero: 'AUT-773001',
        estado: 'Vigente',
        suma: '\$280,000', prima: '\$7,800', period: 'Anual',
        proxPago: '22 sep 2026', deducible: '\$14,000',
      ),
    ],
    notas: [],
  ),
  MockClient(
    id: 'sofia',
    nombre: 'Sofía Ramírez',
    inicial: 'SR',
    color: const Color(0xFFD8453F),
    ocupacion: 'Diseñadora',
    edad: 29,
    ciudad: 'CDMX',
    tel: '+52 55 7777 3456',
    email: 'sofia@studio.mx',
    desde: 'Cliente 2023',
    diasSinContacto: 14,
    polizas: [
      MockPolicy(
        id: 'p6', ramo: 'Gastos Médicos', aseguradora: 'AXA', numero: 'GMM-442201',
        estado: 'Vigente',
        suma: '\$2,000,000', prima: '\$6,200', period: 'Anual',
        proxPago: '5 oct 2026', deducible: '\$12,000',
      ),
    ],
    notas: [],
  ),
];



final mockChatThread = <MockMessage>[
  MockMessage(
    id: 'm1', role: 'ai',
    text: '¡Hola Daniel! Soy tu asistente. Tengo acceso a todos tus clientes, pólizas y recordatorios. ¿En qué te ayudo hoy?',
  ),
  MockMessage(
    id: 'm2', role: 'user',
    text: '¿Cuánto paga Mariana por su auto?',
  ),
  MockMessage(
    id: 'm3', role: 'ai',
    text: 'Mariana Torres paga',
    big: '\$11,300 / año',
    card: MockMsgCard(
      ramo: 'Auto · GNP',
      numero: 'AUT-552190',
      rows: [
        ['Prima anual', '\$11,300'],
        ['Deducible', '\$22,500'],
        ['Suma asegurada', '\$450,000'],
        ['Vence', '4 jun 2026'],
      ],
    ),
  ),
];

final mockSuggestions = [
  '¿Quién vence pronto?',
  '¿Cuánto cobra Javier?',
  'Recuérdame llamar mañana',
  '¿Pagos esta semana?',
];

MockClient? clientById(String id) {
  try {
    return mockClients.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
}

const mockStats = {'polizas': 12, 'clientes': 5};
