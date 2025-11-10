import 'package:flutter/material.dart';

class InstrucoesTela extends StatelessWidget {
  const InstrucoesTela({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(
              context,
            ); // fecha a tela atual e volta para a anterior
          },
          icon: Icon(Icons.arrow_back, color: Color.fromARGB(255, 226, 21, 65)),
        ),
      ),

      body: SafeArea(
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Como Aferir",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Card(
                color: Color(0xff161616),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      leading: Icon(
                        Icons.looks_one_rounded,
                        color: Color.fromARGB(255, 226, 21, 65),
                      ),
                      title: Text(
                        "Preencha completamente o visor",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "Ele ficará vermelho e você conseguirá ver a pulsação",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 10),

              Card(
                color: Color(0xff161616),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      leading: Icon(
                        Icons.looks_two_rounded,
                        color: Color.fromARGB(255, 226, 21, 65),
                      ),
                      title: Text(
                        "Vá para um local iluminado",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "Uma boa aferição requer iluminação ambiente",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 10),

              Card(
                color: Color(0xff161616),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      leading: Icon(
                        Icons.looks_3_rounded,
                        color: Color.fromARGB(255, 226, 21, 65),
                      ),
                      title: Text(
                        "Mantenha seu dedo estável",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "Movimentações bruscas prejudicam a aferição",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 10),

              Card(
                color: Color(0xff161616),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      leading: Icon(
                        Icons.looks_4_rounded,
                        color: Color.fromARGB(255, 226, 21, 65),
                      ),
                      title: Text(
                        "Cubra apenas a câmera",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "Não cubra completamente a lantera, ela é quente",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 10),

              Card(
                color: Color(0xff161616),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      leading: Icon(
                        Icons.looks_5_rounded,
                        color: Color.fromARGB(255, 226, 21, 65),
                      ),
                      title: Text(
                        "Pressione levemente",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "Uma leve pressão melhora a identificação da pulsação",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

  }
}
