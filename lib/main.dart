import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'login_screen.dart'; // Nuestro envoltorio que decide que arrancar, si el loggeo u esta "actividad".

/**
 * Arranca la UI.
 */
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // Para poder acceder al fichero .env
  runApp(
    MaterialApp(
      home: AppWrapper(), // El Wrapper decide qué mostrar
    ),
  );
}

/**
 * AppWrapper determina si la app se mueve a la pantalla de inicio de sesión, u a la principal en
 * función de los datos hallado en SharedPreferences (anterior inicio de sesión si es que lo ha habido).
 */
class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool?
  _isLoggedIn; // Inicializado a Null mientras lee el disco, para mostrar una pantalla de carga

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  // Lee el almacenamiento local al arrancar
  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn =
          prefs.getBool('isLoggedIn') ??
          false; // Si NO ENCUENTRA DATOS PREVIOS, lo pone a false.
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Mientras lee el disco duro, mostramos circulito de carga
    if (_isLoggedIn == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 2. Si la sesión es verdadera, cargamos la App Principal
    if (_isLoggedIn == true) {
      return MyApp();
    }

    // 3. Si no hay sesión, cargamos el Login
    return LoginScreen(
      onLoginSuccess: () {
        setState(() {
          _isLoggedIn =
              true; // Esto forzará a Flutter a redibujar y mostrar la App Principal
        });
      },
    );
  }
}

/**
 * Pantalla cuyo estado no cambia (StatelessWidget).
 * Construye la pantalla como tal, es la que arrancamos en base al main y "runApp()".
 */
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // MaterialApp es el estilo escogido para esta pantalla (Material Design).
    return MaterialApp(
      // "home" devuelve la pantalla inicial, que es "FileListPage".
      home: FileListPage(),
    );
  }
}

/**
 * FileListPage exitiende de StatefulWidget. Todos los elemenos de la UI en Flutter
 * son "Widgets". En este caso, sí que cambia de estado con respecto a los datos que le llegan.
 * Hay que tener en cuenta que los Widgets en Flutter se rigen por los datos de entrada, y que hay
 * Widgets que cambian o NO de estado con respecto a esos datos.
 *
 */
class FileListPage extends StatefulWidget {
  @override
  _FileListPageState createState() => _FileListPageState();
}

// El state de la app, que en función de los datos cambiará la UI.
// SE CONSIDERA LA CLASE PRINCIPAL
class _FileListPageState extends State<FileListPage> {
  String _user = "";
  List files = []; // Lista de archivos a mostrar.
  String _currentPath = ""; // Empieza vacío (raíz del usuario)
  List<String> _navigationHistory = []; // Para poder volver atrás

  // URL de conexión con el servidor.
  final String baseUrl = "${dotenv.env['API_URL']}/archivos";

  // Para el progreso de subida.
  final dio = Dio();
  double uploadProgress = 0.0;

  @override
  void initState() {
    super
        .initState(); // PARECIDO u equivalente a la función "onCreate" en Android.
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _user = prefs.getString('username') ?? "invitado";
    });
    loadFiles(); // Llama a la función que carga los archivos (ubicada más abajo en el código).
    // Se ejecuta al crear la pantalla.
  }

  /**
   * Carga los archivos del servidor, esperando la respuesta deseada
   * del mismo.
   * Es IMPORTANTÍSIMO utilizar la palabra reservada "async" en Flutter para aquellas acciones
   * que requieren solicitudes pesadas (como las HTTP), que deban realizarse "asíncronamente" para
   * NO BLOQUEAR LA UI.
   */
  void loadFiles() async {
    String rutaCompleta =
        _user; // Pillamos la ruta completa (ruta raíz + directorio de usuario logeado)

    // Unimos la ruta completa y la del directorio ACTUAL: Donde estamos "Metidos".
    if (_currentPath.isNotEmpty) {
      rutaCompleta = "$_user/$_currentPath";
    }

    final urlConUsuario =
        '$baseUrl?usuario=$rutaCompleta'; // Construimos la URL con la ruta completa (ruta usuario + donde estemos...)
    final response = await http.get(Uri.parse(urlConUsuario));

    setState(() {
      files = jsonDecode(response.body);
    });
  }

  /**
   * Función encargada de SUBIR ARCHIVOS a nuestro Cloud.
   */
  void uploadFile() async {
    try {
      // Se encarga de abrir el explorador de archivos para que el usuario
      // escoja el mismo para subir.
      // FilePicker -> Abre el explorador de archivos.
      // withData: false -> Indica que no quieres cargar el contenido del archivo en la memoria RAM en ese instante.
      // await da lugar al usuario a que elija archivo.
      final result = await FilePicker.platform.pickFiles(withData: false);

      // Si el usuario NO escoje archivo (pulsa cancelar o vuelve atrás) O existe cualquier problema con el archivo seleccionado
      // (por ejemplo, problema de permisos), en ambos casos, FRENA la petición POST para evitar mayores errores, pues o no se ha
      // seleccionado archivo, u ha habido un error con el elegido.
      if (result == null || result.files.first.path == null) return;

      // Damos un valor inicial a la variable que determinará el progreso de subida a la UI, que anteriormente hemos
      // inicializado en la parte inicial de este mismo state.
      setState(() {
        uploadProgress = 0.0;
      });

      String path = result.files.first.path!;
      String fileName = result.files.first.name;

      // RUTA ACTUAL PARA SUBIDA DE ARCHIVOS
      String destinationPath = _currentPath.isEmpty ? _user : "$_user/$_currentPath";

      // Dio realiza peticiones POST para conocer el estado de subida del archivo, en base a la URL que comunica
      // con nuestro Servidor.
      await dio.post(
        "$baseUrl/upload",
        data: FormData.fromMap({
          "file": await MultipartFile.fromFile(path, filename: fileName),
          "usuario": destinationPath,
        }),
        // Dio llama CONSTANTEMENTE al fragmento onSendProgress durante el envío.
        // sent -> bytes YA enviados al servidor.
        // total -> bytes TOTALES de dicho archivo.
        onSendProgress: (sent, total) {
          setState(() {
            uploadProgress =
                sent /
                total; // Y esta sentencia, quizá la mas importante convierte los Bytes reales en porcentaje de progreso.
          });
        },
      );

      // Aunque parezca redundate, como el valor final puede no verse reflejado, indicamos, una vez el bloque "onSendProgress" ha
      // finalizado totalmente, el valor real del "100%" en la barra de progreso (equivalente a 1.0).
      // Es por ello que aquí, para acabar, cambiamos el estado de la barra de progreso.
      setState(() {
        uploadProgress =
            1.0; // Progreso equivalente al 100%. En Scaffold, figurado más abajo en el código, indicamos a la barra
        // barra de progreso encargada del mismo, que ESTE valor (uploadProgress), es el que debe tomar como
        // referencia para indicar el progreso.
      });

      loadFiles();
    } catch (e) {
      print("ERROR: $e");
    }
  }

  /**
   * Función destinada a crear directorios.
   */
  void createFolder(String folderName) async {

    // RUTA ACTUAL PARA CREACIÓN DE DIRECTORIOS
    String destinationPath = _currentPath.isEmpty ? _user : "$_user/$_currentPath";

    // Construimos la URL con el usuario y el nombre de la nueva carpeta
    final url = '$baseUrl/folder?usuario=$destinationPath&folderName=$folderName';

    try {
      final response = await http.post(Uri.parse(url));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Carpeta creada con éxito'),
            backgroundColor: Colors.green,
          ),
        );
        loadFiles(); // Recargamos la lista para que aparezca
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error al crear carpeta: $e");
    }
  }

  /**
   * Función encargada de borrado de fichero u directorio.
   */
  void deleteFile(String filename) async {

    // RUTA ACTUAL PARA BORRADO DE FICHEROS / DIRECTORIOS
    String destinationPath = _currentPath.isEmpty ? _user : "$_user/$_currentPath";

    // Construimos la URL con el usuario y el nombre del archivo a borrar
    final url = '$baseUrl/delete?usuario=$destinationPath&filename=$filename';

    try {
      final response = await http.delete(Uri.parse(url));

      if (response.statusCode == 200) {
        // Si el borrado en Ubuntu fue un éxito, mostramos mensaje
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Eliminado con éxito'),
            backgroundColor: Colors.green,
          ),
        );
        // Recargamos la lista para que desaparezca el archivo
        loadFiles();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error en la petición de borrado: $e");
    }
  }

  void _dialogConfirmationDeleteFile(String filename) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Eliminar"),
          content: Text("¿Estás seguro de que quieres eliminar '$filename'?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Solo cierra el diálogo
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cierra el diálogo
                deleteFile(
                  filename,
                ); // Llama a la función que acabamos de crear
              },
              child: const Text(
                "Sí, eliminar",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _dialogCreateFolder() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Nueva carpeta"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "Nombre de la carpeta",
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(context); // Cierra el diálogo
                  createFolder(name); // Llama a la función de red
                }
              },
              child: const Text("Crear"),
            ),
          ],
        );
      },
    );
  }

  void _dialogConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Cerrar Sesión"),
          content: const Text("¿Estás seguro de que quieres salir?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                context,
              ), // Si pulsamos cancelar, el diálogo se cierra
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(
                  context,
                ); // Si pulsa en "Aceptar", también cerramos el diálogo pero...

                // 1. Borramos la sesión persistente (Habrá que volver a iniciar sesión).
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', false);

                // 2. Mandamos al usuario a la pantalla de inicio de sesión.
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(onLoginSuccess: () {}),
                    ),
                    (route) =>
                        false, // Borramos el historial de pantallas (esto además de liberar recursos, evita que
                    // el usuario vuelva a acceder pulsando u haciendo gesto de volver atrás.
                  );
                }
              },
              child: const Text("Aceptar", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  /**
   * Pequeña función para determinar el icono de los ficheros. Si no tiene extensión, se
   * trata de un directorio.
   * Si por el contrario la tiene, se le dará un icono acorde.
   */
  IconData getIcon(String fileName) {
    if (!fileName.contains('.')) {
      return Icons.folder;
    }

    String extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.movie;
      case 'mp3':
      case 'm4a':
        return Icons.music_note;
      case 'pdf':
        return Icons.picture_as_pdf;
      default:
        return Icons.insert_drive_file;
    }
  }

  // Scaffold actua como el "layout" de Android, es decir, determina el aspecto de la pantalla a pintar.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( // Si queremos volver atrás de donde sea que estemos a nivel de "árbol de directorios."
        title: Text(
          _currentPath.isEmpty ? "Mis archivos" : _currentPath.split('/').last,
        ),
        leading: _currentPath.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    // Sacamos la última ruta guardada en el historial de rutas
                    _currentPath = _navigationHistory.removeLast();
                  });
                  loadFiles(); // Recargamos la carpeta anterior (el lugar en el que estuvimos previamente, para
                               // "VOLVER" al lugar anterior en el árbol de directorios.
                },
              )
            : null, // Si estamos en la raíz, saca el menú hamburguesa por defecto
      ), // Barra superior
      // Botón con menú inferior derecho para varias opciones (Subir, crear directorio...)
      floatingActionButton: PopupMenuButton<String>(
        // Desplaza el menú hacia arriba para que no tape el botón
        offset: const Offset(0, -110),

        // El botón físico redondo que se verá en pantalla
        child: Material(
          elevation: 6, // Sombra
          shape: const CircleBorder(),
          color: Colors.blueAccent,
          child: const SizedBox(
            width: 56,
            height: 56,
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: 28,
            ), // Usamos el icono de añadir +
          ),
        ),

        // Qué pasa cuando el usuario selecciona una opción
        onSelected: (String value) {
          if (value == 'upload') {
            uploadFile(); // Llamada la función de subida de ficheros
          } else if (value == 'folder') {
            _dialogCreateFolder(); // Llamada a la función que crea directorios
          }
        },

        // Las opciones que se despliegan en el Pop-Up
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'upload',
            child: ListTile(
              leading: Icon(Icons.upload, color: Colors.blueAccent),
              title: Text('Subir archivo'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem<String>(
            value: 'folder',
            child: ListTile(
              leading: Icon(Icons.create_new_folder, color: Colors.green),
              title: Text('Crear carpeta'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),

      // Menú desplegable "Hamburguesa".
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueAccent),
              child: Text(
                'Menú',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            // Por mera decoración e indicación del usuario loggeado, ponemos aquí
            // (En el desplegable del menú hamburguesa), una cabecera para indicar el usuario logeado).
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.blueAccent),
              accountName: Text(
                _user, // Variable de usuario, para determinar el nombre.
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              accountEmail: const Text("Usuario de VGCloud"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  _user.isNotEmpty ? _user[0].toUpperCase() : "U", // Inicial del usuario en mayúscula
                  style: const TextStyle(fontSize: 32, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Cerrar Sesión'),
              onTap: () {
                Navigator.pop(context); // Cierra el menú desplegable primero
                _dialogConfirmation(context); // Abre el diálogo
              },
            ),
          ],
        ),
      ),

      // El CUERPO de la UI de barra superior para abajo.
      body: Column(
        children: [
          // BARRA DE PROGRESO de subida de archivos. Parte superior del body.
          if (uploadProgress > 0 && uploadProgress < 1)
            Padding(
              padding: EdgeInsets.all(8),
              child: LinearProgressIndicator(
                // Indicamos que es una barra de progreso.
                value:
                    uploadProgress, // Utilizamos la barra de progreso utilizada anteriormente.
              ),
            ),

          // LISTA de archivos. Utilizamos "expanded" para indicarle que use la cantidad de pantalla sobrante.
          Expanded(
            child: files.isEmpty
                ? Center(
                    // Para mayor comunicación, si no hay archivos encontrados para el usuario
                    // logeado, indicamos lo pertinente.
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No se han encontrado archivos",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "¡Sube algo pulsando el botón de abajo!",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                // De otra manera, pintamos la lista normalmente.
                : ListView.builder(
                    // Algo así como un "RecyclerView" de Android/Java. Construye la lista con todas las coincidencias (elementos).
                    itemCount: files.length, // Número de elementos totales.
                    itemBuilder: (context, index) {
                      // Se construye PARA CADA ELEMENTO.
                      final file =
                          files[index]; // índice de cada elemento respectivo.
                      final url =
                          "$baseUrl/$file"; // URL que dirige al elemento respectivo.

                      return InkWell(
                        // Parte "INTERACTIVA" de la UI (InkWell). Es decir,
                        // EL MOMENTO EN EL QUE PULSAMOS UN ELEMENTO
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          if (!file.contains('.')) {
                            // Es decir, sin extensión, es UNA CARPETA
                            setState(() {
                              // Guardamos donde estábamos para poder volver
                              _navigationHistory.add(_currentPath);

                              // Actualizamos la ruta actual sumando la nueva carpeta
                              if (_currentPath.isEmpty) {
                                _currentPath = file;
                              } else {
                                _currentPath = "$_currentPath/$file";
                              }
                            });
                            loadFiles(); // Recargamos para ver lo que hay dentro de la carpeta pulsada
                          } else {
                            // Ahora bien, para cargar el archivo al que estamos indicando y que cargue correctamente,
                            // nos cercioramos de que tenemos la ruta correcta al mismo, para ello:

                            // 1. Calculamos la ruta donde está el archivo
                            // Lo que se traduce en, si no hay directorio actual (valor en la variable _currentPath),
                            // entonces estamos en nuestra ruta raíz de usuario aún, por lo que la ruta destino es esa misma.
                            // Por el contrario, si hay valor en _currentPath, es que estamos en otro lado, por lo que conviene
                            // especificar donde, construyendo la ruta de destino deseada (ruta actual + el archivo a visualizar).
                            String rutaDestino = _currentPath.isEmpty ? _user : "$_user/$_currentPath";

                            // 2. Construimos la URL correcta con el parámetro de seguridad
                            final urlParaVisor = "$baseUrl/$file?usuario=$rutaDestino";

                            // Por otro lado, si tiene extensión, es un archivo real. Abres tu visor:
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ViewerPage(urlParaVisor),
                              ),
                            );
                          }
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                getIcon(file),
                                  size: 32,
                                  color: !file.contains('.') ? Colors.amber : Colors.blueGrey
                              ),
                              SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      file,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Archivo",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Botón de confirmación para borrado de archivo
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.grey,
                                ),
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _dialogConfirmationDeleteFile(file);
                                  }
                                },
                                itemBuilder: (BuildContext context) => [
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      title: Text(
                                        'Eliminar',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/**
 * ViewerPage "discrimina" en función del tipo de archivo, es decir,
 * creará una página de visualizado DIFERENTE en función del archivo a visualizar.
 *
 * NOTA -> Para este punto, técnicamente no hace falta más que diferenciar entre mp3, mp4... etc.
 * Esto es porque, en la lógica Backend de SpringBoot, YA HEMOS GESTIONADO la conversión de archivos gracias
 * a ffmpeg, instalado en el servidor, para que la compatibilidad entre Android y iOS esté ASEGURADA, por lo que
 * esta lógica no debe cambiar en consecuencia.
 */
class ViewerPage extends StatelessWidget {
  final String url;

  ViewerPage(this.url);

  // Pinta las interfaz requerida en función del tipo de archivo SELECCIONADO a visualizar.
  @override
  Widget build(BuildContext context) {
    String extension = url
        .split('?')
        .first
        .split('.')
        .last
        .toLowerCase();

    if (extension == "jpg" || extension == "png" || extension == "gif") {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Image.network(url), // Carga la imagen desde internet
        ),
      );
    } else if (extension == "mp4" || extension == "avi" || extension == "mov") {
      return VideoPlayerScreen(url);
    } else if (extension == "mp3" || extension == "m4a") {
      return AudioPlayerScreen(url);
    } else {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("No soportado")),
      );
    }
  }
}

// VIDEO
class VideoPlayerScreen extends StatefulWidget {
  final String url;

  VideoPlayerScreen(this.url);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController controller;

  @override
  void initState() {
    super.initState();
    // INICIA el controlador de vídeo (initialize().)
    controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        setState(() {});
        controller.play(); // Reproduce
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: controller.value.isInitialized
          ? AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
}

// AUDIO
class AudioPlayerScreen extends StatefulWidget {
  final String url;

  AudioPlayerScreen(this.url);

  @override
  _AudioPlayerScreenState createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final player = AudioPlayer(); // REPRODUCTOR DE AUDIO.
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await player.setUrl(widget.url);
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  // Play / Pause MANUAL.
  void togglePlay() async {
    if (isPlaying) {
      await player.pause();
    } else {
      await player.play();
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reproductor MP3")),
      body: Center(
        child: ElevatedButton(
          onPressed: togglePlay,
          child: Text(isPlaying ? "Pausar" : "Reproducir"),
        ),
      ),
    );
  }
}
