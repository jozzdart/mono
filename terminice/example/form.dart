import 'package:terminice/terminice.dart';

void main() {
  final result = form(
      'User Signup',
      [
        const FormFieldSpec(
          name: 'name',
          label: 'Name',
          placeholder: 'Your full name',
          validator: _required,
        ),
        const FormFieldSpec(
          name: 'email',
          label: 'Email',
          placeholder: 'you@example.com',
          validator: _email,
        ),
        const FormFieldSpec(
          name: 'password',
          label: 'Password',
          placeholder: 'minimum 6 characters',
          obscure: true,
          validator: _password,
        ),
      ],
      theme: PromptTheme.pastel);

  if (result == null) {
    infoBox('Cancelled', type: InfoBoxType.warn, theme: PromptTheme.pastel);
  } else {
    infoBox(
      'Thanks, ${result['name']}! Registered ${result['email']}'.trim(),
      type: InfoBoxType.info,
      theme: PromptTheme.pastel,
      title: 'Submission',
    );
  }
}

String? _required(String v) =>
    v.trim().isEmpty ? 'This field is required.' : null;

String? _email(String v) {
  if (v.trim().isEmpty) return 'Email is required.';
  final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  return re.hasMatch(v) ? null : 'Enter a valid email.';
}

String? _password(String v) =>
    v.trim().length < 6 ? 'Password must be at least 6 characters.' : null;
