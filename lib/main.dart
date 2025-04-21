import 'dart:io';
import 'package:flutter/material.dart';
import 'package:poc_gemini_ia/repository.dart';
import 'package:poc_gemini_ia/view_model.dart';
import 'models.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Assistente IA',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Assistente IA'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final GlobalKey<FormState> formState;
  late final ScrollController scrollController;

  bool isLoading = false;

  late final ViewModel viewModel;

  @override
  void didUpdateWidget(covariant MyHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    scrollController = ScrollController();
    viewModel = ViewModel(repository: IARepositoryImpl());
    formState = GlobalKey<FormState>();

    viewModel.addListener(() {
      if (mounted) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: kThemeAnimationDuration,
          curve: Curves.ease,
        );
      }
    });

    viewModel.addSystemInstructions(
      [
        TextPart(
          text: "Você é um agente de uma conta digital.",
        ),
        TextPart(
          text:
              "Sempre que o usuário iniciar uma conversa você pode dar boas vindas para ele informando seu nome e perguntando em que você pode ajuda-lo, exemplo: Olá {fullname}, em que posso te ajudar?.",
        ),
        TextPart(
          text:
              "Seu objetivo é ajudar o usuário a obter as informações de sua conta, você tem os contexto dos dados da conta do usuário.",
        ),
        TextPart(
          text:
              "Sempre quem o usuário solicitar um arquivo, quero que você retorne os bytes desse arquivo.",
        ),
        TextPart(
          text:
              "Caso você não tenha uma informação que o usuário solicitou ou não consiga processar a solicitação do usuário, você deve orienta-lo a entrar em contato com nossa equipe de atendimento no número 0800 000 00000",
        ),
      ],
    );
    viewModel.addContent(
      Content(
        parts: [
          InlinePart(
            mimeType: "text/csv",
            data:
                "dmFsdWVzL2JhbGFuY2VJZCx2YWx1ZXMvYW1vdW50LHZhbHVlcy9jcmVhdGVkQXQKMSwyMDAsMjAyNC0wMS0wMVQwMDowMDowMC4wMDBaCjIsMzAwLDIwMjQtMDEtMDJUMDA6MDA6MDAuMDAwWgozLDQwMCwyMDI0LTAxLTAzVDAwOjAwOjAwLjAwMFoK",
          ),
          InlinePart(
            mimeType: "text/csv",
            data:
                "ZnVsbG5hbWUsY3BmLGVtYWlsLHBob25lLGFkZHJlc3MsYmlydGhEYXRlLGNyZWF0ZWRBdCx1cGRhdGVkQXQKTWFyaWEgSm9zw6kgUm9kcmlndWVzLDEyMy40NTYuNzg5LTAwLG1hcmlhQGdtYWlsLmNvbSwoMTEpIDk5OTk5LTk5OTksIlJ1YSBkb3MgQm9ib3MsIG7CuiAwLCBCYWlycm8gZG9zIEJvYm9zLCBDRVA6IDAwMDAwLTAwMCwgU8OjbyBQYXVsbyAtIFNQLCBCcmFzaWwiLDE5OTAtMDEtMDFUMDA6MDA6MDAuMDAwWiwyMDI0LTAxLTAxVDAwOjAwOjAwLjAwMFosMjAyNC0wMS0wMVQwMDowMDowMC4wMDBaCg==",
          ),
        ],
        role: "user",
      ),
    );

    super.initState();
  }

  @override
  void dispose() {
    formState.currentState?.dispose();
    super.dispose();
  }

  Widget buildWidgetByPart(Part part, String role) {
    if (part is InlinePart && role == 'user') {
      return const SizedBox.shrink();
    }
    return switch (part.runtimeType) {
      TextPart => Align(
          alignment:
              role == 'user' ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8,
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: role == 'user'
                    ? Colors.green.shade200
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                part.toString(),
              ),
            ),
          ),
        ),
      InlinePart || CodeExecutionResultPart => FutureBuilder<File>(
          future: part is InlinePart
              ? part.generateFile()
              : (part as CodeExecutionResultPart).generateFile(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: role == 'user'
                          ? Colors.green.shade200
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "Arquivo sendo gerado...",
                    ),
                  ),
                ),
              );
            }
            return IconButton(
              onPressed: () async {
                viewModel.downloadFile(snapshot.data!);
              },
              icon: const Row(
                children: [
                  Icon(
                    Icons.task,
                  ),
                  Text('Baixar arquivo'),
                  Icon(Icons.file_download),
                ],
              ),
            );
          }),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: ListenableBuilder(
          listenable: viewModel,
          builder: (context, child) {
            return Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Scrollbar(
                      controller: scrollController,
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Column(
                          children: [
                            for (var content in viewModel.contents)
                              for (var part in content.parts)
                                buildWidgetByPart(part, content.role ?? '')
                          ],
                        ),
                      ),
                    ),
                  ),
                  viewModel.isloading
                      ? Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Digitando ...',
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Form(
                      key: formState,
                      child: TextFormField(
                        onFieldSubmitted: (value) {
                          if (formState.currentState?.validate() ?? false) {
                            formState.currentState?.save();
                            formState.currentState?.reset();
                          }
                        },
                        onSaved: (message) async {
                          isLoading = true;
                          setState(() {});
                          viewModel.chatStream(message!).then((value) {
                            isLoading = false;
                            setState(() {});
                          }).catchError((e) {
                            print("ERROR: ${e}");
                            isLoading = false;
                            setState(() {});
                          });
                          ;
                        },
                        decoration: InputDecoration(
                            fillColor: Colors.grey,
                            hintText: 'Digite sua mensagem',
                            border: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                            suffix: IconButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      if (formState.currentState?.validate() ??
                                          false) {
                                        formState.currentState?.save();
                                        formState.currentState?.reset();
                                      }
                                    },
                              icon: const Icon(Icons.send),
                            )),
                      ),
                    ),
                  )
                ],
              ),
            );
          }),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
