import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_data/noel_data.dart';

class AccessPendingPage extends StatelessWidget {
  const AccessPendingPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SizedBox(
        width: 440,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48),
              const SizedBox(height: 16),
              Text(
                'Acceso pendiente',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Tu cuenta necesita un rol activo y las asignaciones correspondientes. Si el problema persiste, contacta al administrador.',
              ),
              TextButton(
                onPressed: () => context.go('/projects'),
                child: const Text('Volver a comprobar'),
              ),
              TextButton(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) context.go('/signin');
                },
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
