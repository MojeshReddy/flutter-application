import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

// ---------------------- Models ----------------------
class PicsumImage {
  final String id;
  final String author;
  final int width;
  final int height;
  final String url;
  final String downloadUrl;

  PicsumImage({
    required this.id,
    required this.author,
    required this.width,
    required this.height,
    required this.url,
    required this.downloadUrl,
  });

  factory PicsumImage.fromJson(Map<String, dynamic> json) => PicsumImage(
        id: json['id'],
        author: json['author'] ?? '',
        width: (json['width'] ?? 0) as int,
        height: (json['height'] ?? 0) as int,
        url: json['url'] ?? '',
        downloadUrl: json['download_url'] ?? '',
      );
}

// ---------------------- Repository ----------------------
class PicsumRepository {
  final http.Client _client;
  PicsumRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<PicsumImage>> fetchImages({int page = 1, int limit = 10}) async {
    final uri = Uri.parse('https://picsum.photos/v2/list?page=$page&limit=$limit');
    final resp = await _client.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Failed to load images: ${resp.statusCode}');
    }
    final List<dynamic> body = json.decode(resp.body);
    return body.map((e) => PicsumImage.fromJson(e)).toList();
  }
}

// ---------------------- Login BLoC ----------------------
abstract class LoginEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class EmailChanged extends LoginEvent {
  final String email;
  EmailChanged(this.email);
  @override
  List<Object?> get props => [email];
}

class PasswordChanged extends LoginEvent {
  final String password;
  PasswordChanged(this.password);
  @override
  List<Object?> get props => [password];
}

class LoginSubmitted extends LoginEvent {}

class LoginState extends Equatable {
  final String email;
  final String password;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;

  LoginState({
    required this.email,
    required this.password,
    required this.isSubmitting,
    required this.isSuccess,
    this.errorMessage,
  });

  factory LoginState.initial() => LoginState(
        email: '',
        password: '',
        isSubmitting: false,
        isSuccess: false,
        errorMessage: null,
      );

  LoginState copyWith({
    String? email,
    String? password,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [email, password, isSubmitting, isSuccess, errorMessage];
}

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginState.initial()) {
    on<EmailChanged>((event, emit) {
      emit(state.copyWith(email: event.email, errorMessage: null));
    });
    on<PasswordChanged>((event, emit) {
      emit(state.copyWith(password: event.password, errorMessage: null));
    });
    on<LoginSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(LoginSubmitted event, Emitter<LoginState> emit) async {
    if (state.email.isEmpty || state.password.isEmpty) {
      emit(state.copyWith(errorMessage: 'Email and password cannot be empty'));
      return;
    }

    emit(state.copyWith(isSubmitting: true, errorMessage: null));
    await Future.delayed(Duration(seconds: 1)); // simulate API delay

    // Always succeed for testing
    emit(state.copyWith(isSubmitting: false, isSuccess: true));
  }
}

// ---------------------- Home BLoC ----------------------
abstract class HomeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class HomeRequested extends HomeEvent {}

abstract class HomeState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoadInProgress extends HomeState {}

class HomeLoadSuccess extends HomeState {
  final List<PicsumImage> images;
  HomeLoadSuccess(this.images);
  @override
  List<Object?> get props => [images];
}

class HomeLoadFailure extends HomeState {
  final String message;
  HomeLoadFailure(this.message);
  @override
  List<Object?> get props => [message];
}

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final PicsumRepository repository;
  HomeBloc({required this.repository}) : super(HomeInitial()) {
    on<HomeRequested>(_onRequested);
  }

  Future<void> _onRequested(HomeRequested event, Emitter<HomeState> emit) async {
    emit(HomeLoadInProgress());
    try {
      final images = await repository.fetchImages(page: 1, limit: 10);
      emit(HomeLoadSuccess(images));
    } catch (e) {
      emit(HomeLoadFailure(e.toString()));
    }
  }
}

// ---------------------- UI ----------------------
void main() {
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login + Picsum App',
      theme: ThemeData(
        textTheme: GoogleFonts.montserratTextTheme(Theme.of(context).textTheme),
        primarySwatch: Colors.blue,
      ),
      home: BlocProvider(create: (_) => LoginBloc(), child: LoginScreen()),
    );
  }
}

class LoginScreen extends StatelessWidget {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocListener<LoginBloc, LoginState>(
          listener: (context, state) {
            if (state.isSuccess) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => RepositoryProvider(
                    create: (_) => PicsumRepository(),
                    child: BlocProvider(
                      create: (ctx) =>
                          HomeBloc(repository: ctx.read<PicsumRepository>())..add(HomeRequested()),
                      child: HomeScreen(),
                    ),
                  ),
                ),
              );
            }
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                onChanged: (v) => context.read<LoginBloc>().add(EmailChanged(v)),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                obscureText: true,
                onChanged: (v) => context.read<LoginBloc>().add(PasswordChanged(v)),
              ),
              SizedBox(height: 12),
              BlocBuilder<LoginBloc, LoginState>(
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed: state.isSubmitting
                        ? null
                        : () => context.read<LoginBloc>().add(LoginSubmitted()),
                    child: state.isSubmitting
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Submit'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Picsum Images')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              if (state is HomeLoadInProgress) return Center(child: CircularProgressIndicator());
              if (state is HomeLoadFailure) return Center(child: Text('Error: ${state.message}'));
              if (state is HomeLoadSuccess) {
                final images = state.images;
                return ListView.separated(
                  itemBuilder: (context, index) => PicsumListCell(image: images[index]),
                  separatorBuilder: (_, __) => SizedBox(height: 12),
                  itemCount: images.length,
                );
              }
              return SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

class PicsumListCell extends StatelessWidget {
  final PicsumImage image;
  const PicsumListCell({required this.image});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width - 24;
    final aspect = image.width > 0 && image.height > 0
        ? (image.height / image.width)
        : 0.6;
    final height = screenWidth * aspect;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: screenWidth,
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              image.downloadUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                              (progress.expectedTotalBytes ?? 1)
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, err, stack) =>
                  Container(color: Colors.grey[300], child: Center(child: Icon(Icons.broken_image))),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          image.author,
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        SizedBox(height: 4),
        Text(
          'Image id: ${image.id} • ${image.width}×${image.height}',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w400, color: Colors.grey[700]),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
