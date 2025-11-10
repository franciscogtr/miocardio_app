import 'package:flutter/material.dart';
import 'package:miocardio_app/telas/atividade_tela.dart';
import 'package:miocardio_app/telas/cardio_tela.dart';
import 'package:miocardio_app/telas/metricas_tela.dart';
import 'package:miocardio_app/telas/pedometer_tela.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';

//Example to setup Bubble Bottom Bar with PageView
class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();

}

class _TelaPrincipalState extends State<TelaPrincipal> {
  PageController controller = PageController(initialPage: 1);
  var selected = 1;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Image.asset('assets/images/logo.png'),
        ),
        title: Text("MioCardio", style: TextStyle(
          fontWeight: FontWeight.bold,
        ),),
      ),


      body: PageView(
        onPageChanged: (controller){
          setState(() {
            selected = controller;
          });
        },
        controller: controller,
        children: const [
           CardioTela(),
           AtividadeTela(),
           MetricasTela(),
        ],
      ),


      bottomNavigationBar: StylishBottomBar(
        backgroundColor: Color(0xff0C0C0C),
        option: BubbleBarOptions(
          // barStyle: BubbleBarStyle.vertical,
          barStyle: BubbleBarStyle.horizontal,
          bubbleFillStyle: BubbleFillStyle.fill,
          // bubbleFillStyle: BubbleFillStyle.outlined,
          opacity: 0.3,
        ),
        iconSpace: 12.0,
        items: [
          BottomBarItem(
            icon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset('assets/images/cardio.png', color: Colors.white54),
            ),
            title: const Text('Aferição'),
            backgroundColor:  Color.fromARGB(255, 226, 21, 65),

            // selectedColor: Colors.pink,
            selectedIcon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset('assets/images/cardio_select.png', color: Color.fromARGB(255, 226, 21, 65)),
            ),
            badgeColor: Color.fromARGB(255, 226, 21, 65),
            showBadge: false,
          ),
          BottomBarItem(
            icon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset('assets/images/footsteps.png', color: Colors.white54),
            ),
            title: const Text('Atividade'),
            selectedIcon:  Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset('assets/images/footsteps_select.png', color: Color.fromARGB(255, 226, 21, 65)),
            ),
            backgroundColor: Color.fromARGB(255, 226, 21, 65),
          ),
          BottomBarItem(
            icon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset('assets/images/graph.png', color: Colors.white54),
            ),
            title: const Text('Métricas'),
            backgroundColor: Color.fromARGB(255, 226, 21, 65),
            selectedIcon:  Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset('assets/images/graph_select.png', color: Color.fromARGB(255, 226, 21, 65)),
            ),
          ),
          // BottomBarItem(
          //   icon: const Icon(Icons.cabin),
          //   title: const Text('Cabin'),
          //   backgroundColor: Colors.purple,
          // ),
        ],
        hasNotch: true,
        currentIndex: selected,
        onTap: (index) {
          setState(() {
            selected = index;
            controller.jumpToPage(index);
          });
        },

        // fabLocation: StylishBarFabLocation.end,
      ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // floatingActionButton: FloatingActionButton(onPressed: () {}),
    );
  }
}