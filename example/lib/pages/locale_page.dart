import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../widgets/widgets.dart';

// VLocale accepts three shapes — mix and match as convenient:
//   1. Generic fallback:        'required': 'Obrigatório'
//   2. Flat type-prefixed:      'string.required': 'Texto obrigatório'
//   3. Nested type-prefixed:    'string': {'required': 'Texto obrigatório'}
//
// Lookup order for a prefixed code (e.g. `string.required`):
// custom prefixed → custom generic → default prefixed → default generic → code.
// Omitted keys fall back to English — this map stays a complete PT-BR template.
const _ptBr = VLocale({
  // The three flat keys that survive in VCode — used as the global backstop
  // when a type-prefixed key is missing.
  'required': 'Obrigatório',
  'invalid_type': 'Esperado {expected}, recebido {received}',
  'custom': 'Valor inválido',

  'string': {
    'not_empty': 'Não pode ser vazio',
    'too_small': 'Deve ter pelo menos {min} caracteres',
    'too_big': 'Deve ter no máximo {max} caracteres',
    'length': 'Deve ter exatamente {length} caracteres',
    'integer': 'Deve ser um número inteiro',
    'numeric': 'Deve ser um número válido',
    'email': 'E-mail inválido',
    'url': 'URL inválida',
    'uuid': 'UUID inválido',
    'ip': 'Endereço IP inválido',
    'format': 'Formato inválido',
    'date': 'Data inválida',
    'time': 'Hora inválida',
    'phone': 'Número de telefone inválido',
    'contains': 'Deve conter "{substring}"',
    'starts_with': 'Deve começar com "{prefix}"',
    'ends_with': 'Deve terminar com "{suffix}"',
    'equals': 'Deve ser igual a "{expected}"',
    'alpha': 'Deve conter apenas letras',
    'alphanumeric': 'Deve conter apenas letras e números',
    'slug': 'Deve ser um slug válido',
    'password':
        'A senha deve ter pelo menos 8 caracteres, incluindo maiúscula, minúscula, número e caractere especial',
    'jwt': 'JWT inválido',
    'card': 'Número do cartão inválido',
  },

  'number': {
    'too_small': 'Deve ser pelo menos {min}',
    'too_big': 'Deve ser no máximo {max}',
    'not_in_range': 'Deve estar entre {min} e {max}',
    'positive': 'Deve ser positivo',
    'negative': 'Deve ser negativo',
    'multiple_of': 'Deve ser múltiplo de {factor}',
    'finite': 'Deve ser finito',
  },

  'int': {
    'even': 'Deve ser par',
    'odd': 'Deve ser ímpar',
    'prime': 'Deve ser primo',
  },

  'double': {
    'decimal': 'Deve ser um número decimal',
    'integer': 'Deve ser um número inteiro',
  },

  'bool': {
    'is_true': 'Deve ser verdadeiro',
    'is_false': 'Deve ser falso',
  },

  'date': {
    'too_small': 'Deve ser após {date}',
    'too_big': 'Deve ser antes de {date}',
    'not_in_range': 'Deve estar entre {min} e {max}',
    'weekday': 'Deve ser dia útil',
    'weekend': 'Deve ser fim de semana',
    'age': 'Idade fora do intervalo permitido',
  },

  'array': {
    'too_small': 'Deve ter pelo menos {min} itens',
    'too_big': 'Deve ter no máximo {max} itens',
    'unique': 'Deve conter valores únicos',
    'contains_all': 'Deve conter todos os valores obrigatórios',
  },

  'map': {
    'unrecognized_key': 'Chave não reconhecida "{key}"',
    'fields_not_equal': '{field} deve ser igual a {other}',
  },

  'enum': {
    'invalid': 'Valor inválido. Esperado um de: {values}',
  },
  'literal': {
    'invalid': 'Esperado "{expected}", recebido "{received}"',
  },
  'union': {
    'invalid': 'Valor não corresponde a nenhum dos tipos',
  },
});

const _en = VLocale();

enum _Lang { en, pt }

class LocalePage extends StatefulWidget {
  const LocalePage({super.key});

  @override
  State<LocalePage> createState() => _LocalePageState();
}

class _LocalePageState extends State<LocalePage> {
  late VForm<Map<String, dynamic>> _form;
  _Lang _lang = _Lang.en;

  @override
  void initState() {
    super.initState();
    _form = V.map({
      'name': V.string().min(3),
      'email': V.string().email(),
      'age': V.int().min(18),
    }).form();
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  void _switchLocale(_Lang lang) {
    _lang = lang;
    V.setLocale(lang == _Lang.pt ? _ptBr : _en);
  }

  VField<String> get _name => _form.field('name');
  VField<String> get _email => _form.field('email');
  VField<int> get _age => _form.field('age');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Multi Language')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form.key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InfoCard(
                'Validart supports custom locales via V.setLocale(). '
                'Switch between English and Portuguese using the dropdown '
                'below, then tap Submit to see error messages in the '
                'selected language. No need to rebuild the form — error '
                'messages are resolved at validation time.',
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<_Lang>(
                decoration: const InputDecoration(labelText: 'Language'),
                initialValue: _lang,
                items: const [
                  DropdownMenuItem(value: _Lang.en, child: Text('English')),
                  DropdownMenuItem(
                    value: _Lang.pt,
                    child: Text('Português'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) _switchLocale(val);
                },
              ),
              const SizedBox(height: 24),
              VTextField(
                field: _name,
                label: 'Name',
              ),
              const SizedBox(height: 16),
              VTextField(
                field: _email,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                onChanged: (value) => _age.onChanged(int.tryParse(value)),
                validator: (_) => _age.validator(_age.value),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _form.validate(),
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
