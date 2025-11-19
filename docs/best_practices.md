Basado en la documentación oficial en: [Buenas prácticas — Documentación de Godot Engine (4.x) en español](https://docs.godotengine.org/es/4.x/tutorials/best_practices/)

# **Buenas prácticas**

## **Introducción**

Esta serie es una colección de buenas prácticas para ayudarte a trabajar de forma eficiente con Godot. Godot permite una gran flexibilidad en la forma de estructurar el código base de un proyecto y dividirlo en escenas. Cada enfoque tiene sus pros y sus contras, y pueden ser difíciles de sopesar hasta que haya trabajado con el motor durante el tiempo suficiente. Siempre hay varias formas de estructurar tu código y resolver problemas específicos de programación. Sería imposible cubrirlos a todos aquí. Por esa razón cada artículo parte de un problema del mundo real. Desglosaremos cada problema en preguntas fundamentales, sugeriremos soluciones, analizaremos los pros y contras de cada opción, y destacaremos la mejor forma de proceder para el problema en cuestión.

Deberías empezar leyendo **Aplicando los principios orientados a objetos en Godot**. Explica cómo se relacionan los nodos y escenas de Godot con las clases y objetos de otros lenguajes de programación orientados a objetos. Te ayudará a darle sentido al resto de la serie.

## **Nota**

Las buenas prácticas en Godot se basan en principios de diseño orientado a objetos. Utilizamos herramientas como el principio de responsabilidad única y la encapsulación.

## **Aplicando los principios orientados a objetos en Godot**

El motor ofrece dos formas principales de crear objetos reutilizables: scritps y escenas. Ninguna de ellas define técnicamente las clases por debajo. Aún así, muchas de las mejores prácticas usando Godot implican aplicar los principios de la programación orientada a objetos a los scripts y escenas que componen su juego. Por eso es útil entender cómo podemos pensar en ellos como clases. Esta guía explica brevemente cómo funcionan los guiones y escenas en el núcleo del motor para ayudarlo a comprender cómo funcionan bajo el capó.

### **_Cómo funcionan los scripts en el motor_**

El motor provee clases internas como Node. Puedes extenderlas para crear tipos derivados usando un script. Estos scripts no son técnicamente clases. En cambio, son recursos que le dicen al motor una secuencia de inicializaciones para realizar en una de las clases integradas del motor.

Las clases internas de Godot tienen métodos que registran los datos de una clase mediante una ClassDB. Esta base de datos proporciona acceso en tiempo de ejecución a información de la clase. ClassDB contiene información sobre las clases como:

- Propiedades.
- Métodos.
- Constantes.
- Señales.

Esta ClassDB es lo que los objetos verifican cuando realizan una operación como acceder a una propiedad o llamar a un método. Comprueba los registros de la base de datos y los registros de tipos base del objeto para ver si el objeto admite la operación.

Uniendo un Script a tu objeto extiende los métodos, propiedades y señales disponibles de la ClassDB.

#### **Nota**

Incluso los scripts que no usan la palabra clave `extends` heredan implícitamente de la clase base del motor RefCounted. Como resultado, puedes crear instancias de scripts sin la palabra clave `extends` del código. Sin embargo, dado que extienden RefCounted, no puedes adjuntarlos a un Node.

### **_Escenas_**

El comportamiento de las escenas tiene muchas similitudes con las clases, por lo que puede tener sentido pensar en una escena como una clase. Las escenas son grupos de nodos reutilizables, instantáneos y heredables.

Crear una escena es similar a tener un script que crea nodos y los agrega como niños usando `add_child()`. A menudo emparejamos una escena con un nodo raíz con script que hace uso de los nodos de la escena. Como tal, el script extiende la escena al agregarle un comportamiento mediante código imperativo.

El contenido de una escena ayuda a definir:

- Qué nodos están disponibles al script.
- Cómo están organizados.
- Cómo se inicializan.
- Qué conexiones de señales tienen entre ellos.

#### **¿Por qué es algo de esto importante para la organización de la escena?**

Porque las instancias de escenas _son_ objetos. Como resultado, muchos principios orientados a objetos que se aplican al código escrito también se aplican a escenas: responsabilidad única, encapsulación y otros.

La escena es siempre una extensión del script adjunto a su nodo raíz, por lo que puede interpretarla como parte de una clase. La mayoría de las técnicas explicadas en esta serie de mejores prácticas se basan en este punto.

## [**Organización de la escena**](https://docs.godotengine.org/es/4.x/tutorials/best_practices/scene_organization.html#scene-organization)

This article covers topics related to the effective organization of scene content. Which nodes should you use? Where should you place them? How should they interact?

### **_Cómo crear relaciones de manera eficiente_**

Cuando los usuarios de Godot comienzan a crear sus propias escenas, normalmente se encuentran con el siguiente problema:

Crean la primer escena y la llenan con contenido para luego terminar guardando las ramas en escenas separadas a medida que la sensación de que se deben separar cosas comienza a acumularse. Sin embargo, notan que las referencias rígidas de las que dependían, ya no son posibles de usar. Reutilizar la escena en muchos lugares genera problemas porque las rutas de los nodos no llegan a su destino y las conexiones de las señales creadas en el editor se rompen.

To fix these problems, you must instantiate the sub-scenes without them requiring details about their environment. You need to be able to trust that the sub-scene will create itself without being picky about how it's used.

Una de las mayores cosas a considerar en POO es mantener clases enfocadas, de propósito simple, con vínculos no estrictos ([loose coupling](https://en.wikipedia.org/wiki/Loose_coupling) ) respecto a otras partes del proyecto. Esto mantiene pequeño el tamaño de los objetos (para facilitar el mantenimiento) y mejora la reusabilidad.

Estas buenas prácticas POO tienen _muchas_ ramificaciones para buenas prácticas en estructura de escenas y uso de scripts.

**If at all possible, you should design scenes to have no dependencies.** That is, you should create scenes that keep everything they need within themselves.

Si una escena debe interactuar en un contexto externo, los desarrolladores experimentados recomiendan el uso de [Inyección de dependencias](https://es.wikipedia.org/wiki/Inyeccion_de_dependencias). Esta técnica implica que una API de alto nivel proporcione las dependencias de la API de bajo nivel. ¿Por qué hacer esto? Porque las clases que dependen de su entorno externo pueden desencadenar errores y comportamientos inesperados sin darse cuenta.

To do this, you must expose data and then rely on a parent context to initialize it:

1. Conectando una señal. Es extremadamente seguro, pero solo debe ser utilizado como "respuesta" a un comportamiento, nunca para iniciarlo. Por convención, los nombres de las señales normalmente están en tiempo pasado, como por ejemplo "entered" (ingresó), "skill_activated" (se activó la habilidad) o "item_collected" (se recolectó el item).

   GDScriptC\#C++

   \# Parent $Child.signal_name.connect(method_on_the_object)

   \# Child signal_name.emit() \# Triggers parent-defined behavior.

   Copiar al portapapeles

   // Parent GetNode("Child").Connect("SignalName", Callable.From(ObjectWithMethod.MethodOnTheObject));

   // Child EmitSignal("SignalName"); // Triggers parent-defined behavior.

   Copiar al portapapeles

   // Parent Node \*node \= get_node\<Node\>("Child"); if (node \!= nullptr) { // Note that get_node may return a nullptr, which would make calling the connect method crash the engine if "Child" does not exist\! // So unless you are 1000% sure get_node will never return a nullptr, it's a good idea to always do a nullptr check. node-\>connect("signal_name", callable_mp(this, \&ObjectWithMethod::method_on_the_object)); }

   // Child emit_signal("signal_name"); // Triggers parent-defined behavior.

   Copiar al portapapeles

2. Llamar a un método. Usado para iniciar un comportamiento.

   GDScriptC\#C++

   \# Parent $Child.method_name \= "do"

   \# Child, assuming it has String property 'method_name' and method 'do'. call(method_name) \# Call parent-defined method (which child must own).

   Copiar al portapapeles

   // Parent GetNode("Child").Set("MethodName", "Do");

   // Child Call(MethodName); // Call parent-defined method (which child must own).

   Copiar al portapapeles

   // Parent Node \*node \= get_node\<Node\>("Child"); if (node \!= nullptr) { node-\>set("method_name", "do"); }

   // Child call(method_name); // Call parent-defined method (which child must own).

   Copiar al portapapeles

3. Inicializar una propiedad [Callable](https://docs.godotengine.org/es/4.x/classes/class_callable.html#class-callable). Es más seguro que establecer un método como propiedad del método . Se utiliza para iniciar el comportamiento.

   GDScriptC\#C++

   \# Parent $Child.func_property \= object_with_method.method_on_the_object

   \# Child func_property.call() \# Call parent-defined method (can come from anywhere).

   Copiar al portapapeles

   // Parent GetNode("Child").Set("FuncProperty", Callable.From(ObjectWithMethod.MethodOnTheObject));

   // Child FuncProperty.Call(); // Call parent-defined method (can come from anywhere).

   Copiar al portapapeles

   // Parent Node \*node \= get_node\<Node\>("Child"); if (node \!= nullptr) { node-\>set("func_property", Callable(\&ObjectWithMethod::method_on_the_object)); }

   // Child func_property.call(); // Call parent-defined method (can come from anywhere).

   Copiar al portapapeles

4. Inicializa un Nodo u otra referencia de Objeto.

   GDScriptC\#C++

   \# Parent $Child.target \= self

   \# Child print(target) \# Use parent-defined node.

   Copiar al portapapeles

   // Parent GetNode("Child").Set("Target", this);

   // Child GD.Print(Target); // Use parent-defined node.

   Copiar al portapapeles

   // Parent Node \*node \= get_node\<Node\>("Child"); if (node \!= nullptr) { node-\>set("target", this); }

   // Child UtilityFunctions::print(target);

   Copiar al portapapeles

5. Inicializar un NodePath.

   GDScriptC\#C++

   \# Parent $Child.target_path \= ".."

   \# Child get_node(target_path) \# Use parent-defined NodePath.

   Copiar al portapapeles

   // Parent GetNode("Child").Set("TargetPath", NodePath(".."));

   // Child GetNode(TargetPath); // Use parent-defined NodePath.

   Copiar al portapapeles

   // Parent Node \*node \= get_node\<Node\>("Child"); if (node \!= nullptr) { node-\>set("target_path", NodePath("..")); }

   // Child get_node\<Node\>(target_path); // Use parent-defined NodePath.

   Copiar al portapapeles

These options hide the points of access from the child node. This in turn keeps the child **loosely coupled** to its environment. You can reuse it in another context without any extra changes to its API.

Nota

Although the examples above illustrate parent-child relationships, the same principles apply towards all object relations. Nodes which are siblings should only be aware of their own hierarchies while an ancestor mediates their communications and references.

GDScriptC\#C++

\# Parent $Left.target \= $Right.get_node("Receiver")

\# Left var target: Node func execute(): \# Do something with 'target'.

\# Right func \_init(): var receiver \= Receiver.new() add_child(receiver)

Copiar al portapapeles

// Parent GetNode\<Left\>("Left").Target \= GetNode("Right/Receiver");

public partial class Left : Node { public Node Target \= null;

```
public void Execute()
{
    // Do something with 'Target'.
}
```

}

public partial class Right : Node { public Node Receiver \= null;

```
public Right()
{
    Receiver \= ResourceLoader.Load<Script\>("Receiver.cs").New();
    AddChild(Receiver);
}
```

}

Copiar al portapapeles

// Parent get_node\<Left\>("Left")-\>target \= get_node\<Node\>("Right/Receiver");

class Left : public Node { GDCLASS(Left, Node)

```
protected:
	static void \_bind\_methods() {}

public:
	Node \*target \= nullptr;

	Left() {}

	void execute() {
		// Do something with 'target'.
	}
```

};

class Right : public Node { GDCLASS(Right, Node)

```
protected:
	static void \_bind\_methods() {}

public:
	Node \*receiver \= nullptr;

	Right() {
		receiver \= memnew(Node);
		add\_child(receiver);
	}
```

};

Copiar al portapapeles

The same principles also apply to non-Node objects that maintain dependencies on other objects. Whichever object owns the other objects should manage the relationships between them.

Advertencia

You should favor keeping data in-house (internal to a scene), though, as placing a dependency on an external context, even a loosely coupled one, still means that the node will expect something in its environment to be true. The project's design philosophies should prevent this from happening. If not, the code's inherent liabilities will force developers to use documentation to keep track of object relations on a microscopic scale; this is otherwise known as development hell. Writing code that relies on external documentation to use it safely is error-prone by default.

To avoid creating and maintaining such documentation, you convert the dependent node ("child" above) into a tool script that implements `_get_configuration_warnings()`. Returning a non-empty PackedStringArray from it will make the Scene dock generate a warning icon with the string(s) as a tooltip by the node. This is the same icon that appears for nodes such as the [Area2D](https://docs.godotengine.org/es/4.x/classes/class_area2d.html#class-area2d) node when it has no child [CollisionShape2D](https://docs.godotengine.org/es/4.x/classes/class_collisionshape2d.html#class-collisionshape2d) nodes defined. The editor then self-documents the scene through the script code. No content duplication via documentation is necessary.

Una GUI como esta puede informar mejor a los usuarios del proyecto sobre la existencia de información crítica sobre un Nodo. ¿Tiene dependencias externas? ¿se han satisfecho esas dependencias?. Otros programadores, y especialmente los diseñadores y escritores, necesitarán instrucciones claras en los mensajes que les indiquen qué hacer para configurarlo.

So, why does all this complex switcheroo work? Well, because scenes operate best when they operate alone. If unable to work alone, then working with others anonymously (with minimal hard dependencies, i.e. loose coupling) is the next best thing. Inevitably, changes may need to be made to a class, and if these changes cause it to interact with other scenes in unforeseen ways, then things will start to break down. The whole point of all this indirection is to avoid ending up in a situation where changing one class results in adversely affecting other classes dependent on it.

Tanto scripts y escenas, como clases de extensión del motor, deben apegarse a _todos_ los principios POO. Ejemplos incluyen...

- [SOLID](https://es.wikipedia.org/wiki/SOLID)

- [DRY](https://es.wikipedia.org/wiki/No_te_repitas)

- [KISS](https://es.wikipedia.org/wiki/Principio_KISS)

- [YAGNI](https://es.wikipedia.org/wiki/YAGNI)

#### **Eligiendo una estructura de árbol de nodos**

You might start to work on a game but get overwhelmed by the vast possibilities before you. You might know what you want to do, what systems you want to have, but _where_ do you put them all? How you go about making your game is always up to you. You can construct node trees in countless ways. If you are unsure, this guide can give you a sample of a decent structure to start with.

A game should always have an "entry point"; somewhere you can definitively track where things begin so that you can follow the logic as it continues elsewhere. It also serves as a bird's eye view of all other data and logic in the program. For traditional applications, this is normally a "main" function. In Godot, it's a Main node.

- Nodo "Main" (main.gd)

The `main.gd` script will serve as the primary controller of your game.

Then you have an in-game "World" (a 2D or 3D one). This can be a child of Main. In addition, you will need a primary GUI for your game that manages the various menus and widgets the project needs.

- Nodo "Main" (main.gd)

  - Node2D/Node3D "World" (game_world.gd)

  - Control "GUI" (gui.gd)

When changing levels, you can then swap out the children of the "World" node. [Changing scenes manually](https://docs.godotengine.org/es/4.x/tutorials/scripting/change_scenes_manually.html#doc-change-scenes-manually) gives you full control over how your game world transitions.

The next step is to consider what gameplay systems your project requires. If you have a system that...

1. monitorea todos los datos internamente

2. debería ser accesible globalmente

3. debería existir de manera aislada

... then you should create an [autoload 'singleton' node](https://docs.godotengine.org/es/4.x/tutorials/scripting/singletons_autoload.html#doc-singletons-autoload).

Nota

Para juegos pequeños, una alternativa simple con menor control podría ser tener un singleton "Game" que simplemente llame al método [SceneTree.change_scene_to_file()](https://docs.godotengine.org/es/4.x/classes/class_scenetree.html#class-scenetree-method-change-scene-to-file) para intercambiar el contenido de la escena principal. Esta estructura mantiene a "World" como un nodo principal del juego.

Any GUI would also need to be either a singleton, a transitory part of the "World", or manually added as a direct child of the root. Otherwise, the GUI nodes would also delete themselves during scene transitions.

If you have systems that modify other systems' data, you should define those as their own scripts or scenes, rather than autoloads. For more information, see [Autoloads versus regular nodes](https://docs.godotengine.org/es/4.x/tutorials/best_practices/autoloads_versus_internal_nodes.html#doc-autoloads-versus-internal-nodes).

Each subsystem within your game should have its own section within the SceneTree. You should use parent-child relationships only in cases where nodes are effectively elements of their parents. Does removing the parent reasonably mean that the children should also be removed? If not, then it should have its own place in the hierarchy as a sibling or some other relation.

Nota

In some cases, you need these separated nodes to _also_ position themselves relative to each other. You can use the [RemoteTransform](https://docs.godotengine.org/es/4.x/classes/class_remotetransform3d.html#class-remotetransform3d) / [RemoteTransform2D](https://docs.godotengine.org/es/4.x/classes/class_remotetransform2d.html#class-remotetransform2d) nodes for this purpose. They will allow a target node to conditionally inherit selected transform elements from the Remote\* node. To assign the `target` [NodePath](https://docs.godotengine.org/es/4.x/classes/class_nodepath.html#class-nodepath), use one of the following:

1. Un nodo externo confiable, como un nodo padre, para mediar en la asignación.

2. A group, to pull a reference to the desired node (assuming there will only ever be one of the targets).

When you should do this is subjective. The dilemma arises when you must micro-manage when a node must move around the SceneTree to preserve itself. For example...

- Agregar un nodo "jugador" a un "escenario".

- Need to change rooms, so you must delete the current room.

- Before the room can be deleted, you must preserve and/or move the player.

  Si la memoria no es un problema, si puedes...

  - Create the new room.

  - Move the player to the new room.

  - Delete the old room.

  If memory is a concern, instead you will need to...

  - Mover el jugador a algún lugar en el árbol de escenas.

  - Borrar el escenario.

  - Instanciar el escenario nuevo.

  - Re-add the player to the new room.

The issue is that the player here is a "special case" where the developers must _know_ that they need to handle the player this way for the project. The only way to reliably share this information as a team is to _document_ it. Keeping implementation details in documentation is dangerous. It's a maintenance burden, strains code readability, and unnecessarily bloats the intellectual content of a project.

In a more complex game with larger assets, it can be a better idea to keep the player somewhere else in the SceneTree entirely. This results in:

1. Mayor consistencia.

2. No hay "casos especiales" que deban ser documentados y mantenidos en algún lugar.

3. No hay oportunidad de que sucedan esos errores porque algún detalle no se tuvo en cuenta.

In contrast, if you ever need a child node that does _not_ inherit the transform of its parent, you have the following options:

1. The **declarative** solution: place a [Node](https://docs.godotengine.org/es/4.x/classes/class_node.html#class-node) in between them. Since it doesn't have a transform, they won't pass this information to its children.

2. La solución **imperativa**: Usa la propiedad `top_level` del nodo [CanvasItem](https://docs.godotengine.org/es/4.x/classes/class_canvasitem.html#class-canvasitem-property-top-level) or [Node3D](https://docs.godotengine.org/es/4.x/classes/class_node3d.html#class-node3d-property-top-level). Esto hará que el nodo ignore el transform heredado.

Nota

If building a networked game, keep in mind which nodes and gameplay systems are relevant to all players versus those just pertinent to the authoritative server. For example, users do not all need to have a copy of every players' "PlayerController" logic \- they only need their own. Keeping them in a separate branch from the "world" can help simplify the management of game connections and the like.

La clave para la organización de la escena es considerar el Árbol de Escenas en términos relacionales más que espaciales. ¿Los nodos dependen de la existencia de sus padres? Si no es así, entonces pueden prosperar por sí mismos en otro lugar. Si son dependientes, entonces es lógico que sean hijos de ese padre (y probablemente parte de la escena de ese padre si no lo son ya).

Does this mean nodes themselves are components? Not at all. Godot's node trees form an aggregation relationship, not one of composition. But while you still have the flexibility to move nodes around, it is still best when such moves are unnecessary by default.

## [**Cuándo usar escenas y cuándo scripts**](https://docs.godotengine.org/es/4.x/tutorials/best_practices/scenes_versus_scripts.html#when-to-use-scenes-versus-scripts)

Ya hemos cubierto la diferencia entre escenas y scripts. Los scripts definen una extensión de clases del motor con código imperativo, las escenas lo hacen con código declarativo.

Each system's capabilities are different as a result. Scenes can define how an extended class initializes, but not what its behavior actually is. Scenes are often used in conjunction with a script, the scene declaring a composition of nodes, and the script adding behavior with imperative code.

### **_Tipos anónimos_**

Es posible definir escenas completamente usando sólo scripts. Esto es en escencia lo que hace el editor de Godot, sólo que lo hace en el constructor C++ de sus objetos.

El dilema puede surgir al tener que elegir cuál usar. Crear instancias de un script es idéntico a crear clases en el motor, por lo que manipular escenas requiere un cambio en el API:

GDScriptC\#

const MyNode \= preload("my_node.gd") const MyScene \= preload("my_scene.tscn") var node \= Node.new() var my_node \= MyNode.new() \# Same method call. var my_scene \= MyScene.instantiate() \# Different method call. var my_inherited_scene \= MyScene.instantiate(PackedScene.GEN_EDIT_STATE_MAIN) \# Create scene inheriting from MyScene.

Copiar al portapapeles

using Godot;

public partial class Game : Node { public static CSharpScript MyNode { get; } \= GD.Load\<CSharpScript\>("res://Path/To/MyNode.cs"); public static PackedScene MyScene { get; } \= GD.Load\<PackedScene\>("res://Path/To/MyScene.tscn"); private Node \_node; private Node \_myNode; private Node \_myScene; private Node \_myInheritedScene;

```
public Game()
{
    \_node \= new Node();
    \_myNode \= MyNode.New().As<Node\>();
    // Different than calling new() or MyNode.New(). Instantiated from a PackedScene.
    \_myScene \= MyScene.Instantiate();
    // Create scene inheriting from MyScene.
    \_myInheritedScene \= MyScene.Instantiate(PackedScene.GenEditState.Main);
}
```

}

Copiar al portapapeles

Además, los scripts funcionan un poco más lentos que las escenas debido a la diferencia de velocidad entre el motor y el código del script. Mientras más grande sea, más complejo es el nodo, lo que nos da una mayor razón para construirlo como escena.

### **_Tipos con nombre_**

Los scripts se pueden registrar como nuevo tipo en el editor mismo. Esto muestra el tipo nuevo de nodo o recurso en el diálogo de creación con un icono opcional. En esos casos, la habilidad del usuario para usar scripts es mucho más simplificada. En lugar de tener que...

1. Conocer el tipo base del script que quieran usar.

2. Crear una instancia de un tipo base.

3. Agrega el script al nodo.

Con un script registrado, el tipo del script se convierte en una opción de creación como los demás Node y Resource en el sistema. No es necesario hacer nada de lo mostrado anteriormente, el diálogo de creación además tiene una barra de búsqueda donde se puede buscar el tipo por nombre.

Existen dos sistemas para registrar tipos:

- [Tipos Personalizados](https://docs.godotengine.org/es/4.x/tutorials/plugins/editor/making_plugins.html#doc-making-plugins)

  - Solo para el editor. Los tipos con nombre no son accesibles en tiempo de ejecución.

  - No soporta tipos personalizados heredados.

  - Una herramienta inicializadora. Crea el nodo con el script, nada más.

  - El editor no está pendiente del tipo del script o su relación con otros tipos del engine o scripts.

  - Permite al usuario definir un icono.

  - Funciona para todos los lenguajes de scripting porque funciona con los recursos Script de manera abstracta.

  - Se configura usando [EditorPlugin.add_custom_type](https://docs.godotengine.org/es/4.x/classes/class_editorplugin.html#class-editorplugin-method-add-custom-type).

- [Script Classes](https://docs.godotengine.org/es/4.x/tutorials/scripting/gdscript/gdscript_basics.html#doc-gdscript-basics-class-name)

  - Accesible en el editor y en tiempo de ejecución.

  - Muestra las relaciones de herencia de manera completa.

  - Crea el nodo con el script, pero también cambia el tipo o extiende el tipo desde el editor.

  - El editor está pendiente de la relación de herencia entre scripts, clases de script y clases C++ del motor.

  - Permite al usuario definir un icono.

  - Los desarrolladores que trabajan sobre el motor deben agregar soporta para lenguajes manualmente (tanto la exposición del nombre como la accesibilidad en tiempo de ejecución).

  - El editor escanea las carpetas del proyecto y registra cualquier nombre expuesto para todos los lenguajes de scripting. Cada lenguaje de scripting debe incorporar su propio soporte para exponer esta información.

Ambas metodologías agregan nombres al diálogo de creación, pero para clases de script en particular, también permite a los usuarios acceder por el nombre del tipo sin necesidad de cargar el recurso de script. La creación de instancias y acceso a constantes o métodos estáticos es viable desde cualquier parte.

Con características como esta, puede preferirse que un tipo sea un script sin una escena debido a la facilidad de uso que le da a los usuarios. Quienes estén desarrollando plugins o creando herramientas propias para diseñadores, encontrarán mucho más sencillo hacer las cosas de este modo.

Un aspecto negativo de esto es que implica tener que usar mucha programación imperativa.

### **_Rendimiento de Script vs a PackedScene_**

Un último aspecto a considerar al elegir las escenas y los scripts es la velocidad de ejecución.

A medida que aumenta el tamaño de los objetos, el tamaño necesario de los scripts para crearlos e inicializarlos aumenta mucho. La creación de jerarquías de nodos demuestra esto. La lógica de cada nodo puede tener varios cientos de líneas de código de longitud.

El ejemplo de código a continuación crea un nuevo `Nodo`, cambia su nombre, le asigna un script, establece su padre futuro como propietario para que se guarde en el disco junto con él, y finalmente lo agrega como hijo del Nodo `principal`:

GDScriptC\#

\# main.gd extends Node

func \_init(): var child \= Node.new() child.name \= "Child" child.script \= preload("child.gd") add_child(child) child.owner \= self

Copiar al portapapeles

using Godot;

public partial class Main : Node { public Node Child { get; set; }

```
public Main()
{
    Child \= new Node();
    Child.Name \= "Child";
    var childID \= Child.GetInstanceId();
    Child.SetScript(GD.Load<Script\>("res://Path/To/Child.cs"));
    // SetScript() causes the C# wrapper object to be disposed, so obtain a new
    // wrapper for the Child node using its instance ID before proceeding.
    Child \= (Node)GodotObject.InstanceFromId(childID);
    AddChild(Child);
    Child.Owner \= this;
}
```

}

Copiar al portapapeles

El código de secuencia de comandos como este es mucho más lento que el código C++ del lado del motor. Cada instrucción realiza una llamada a la API de scripting que conduce a muchas "búsquedas" en el back-end para encontrar la lógica a ejecutar.

Las escenas ayudan a evitar este problema de rendimiento. [PackedScene](https://docs.godotengine.org/es/4.x/classes/class_packedscene.html#class-packedscene), el tipo base del que heredan las escenas, define recursos que usan datos serializados para crear objetos. El motor puede procesar escenas en lotes en el back-end y proporcionar un rendimiento mucho mejor que los scripts.

### **_Conclusión_**

El mejor enfoque consiste en considerar lo siguiente:

- Si se desea crear una herramienta básica que será reutilizada en distintos proyectos y donde gente de todo tipo de nivel la usará (incluyendo aquellos que no se llaman a si mismos "programadores"), entonces hay chances de que deba ser un script, probablemente uno con un nombre/icono personalizado.

- Si se desea crear un concepto que es particular para el juego, entonces debe ser una escena. Las escenas son más fáciles de revisar/editar y proveen más seguridad que los scripts.

- Si uno desea darle un nombre a una escena, también se puede hacer algo así declarando una clase script y dándole la escena como constante. De este modo el script se vuelve un espacio de nombres:

  GDScriptC\#

  \# game.gd class_name Game \# extends RefCounted, so it won't show up in the node creation dialog. extends RefCounted

  const MyScene \= preload("my_scene.tscn")

  \# main.gd extends Node func \_ready(): add_child(Game.MyScene.instantiate())

## [**Autoloads frente a nodos corrientes**](https://docs.godotengine.org/es/4.x/tutorials/best_practices/autoloads_versus_internal_nodes.html#autoloads-versus-regular-nodes)

Godot ofrece una característica para cargar nodos automáticamente en la raíz de tu proyecto, permitiéndote acceder a ellos globalmente, que puede cumplir el rol de un Singleton: [Singletons (Autoload)](https://docs.godotengine.org/es/4.x/tutorials/scripting/singletons_autoload.html#doc-singletons-autoload). Estos nodos auto-cargados no se liberan cuando cambias la escena desde código con [SceneTree.change_scene_to_file](https://docs.godotengine.org/es/4.x/classes/class_scenetree.html#class-scenetree-method-change-scene-to-file).

En esta guía aprenderás cuándo usar la función Autoload, y técnicas que puedes usar para evitarlo.

### **_El problema del audio con cortes_**

Otros motores pueden fomentar la creación clases gestoras, singletons que organizan mucha funcionalidad en un objeto accesible globalmente. Godot ofrece varias maneras de evitar un estado global gracias al árbol de nodos y las señales.

Por ejemplo, digamos que estamos construyendo un juego de plataformas y queremos recoger monedas que reproducen un efecto de sonido. Hay uno nodo para ello: el [AudioStreamPlayer](https://docs.godotengine.org/es/4.x/classes/class_audiostreamplayer.html#class-audiostreamplayer). Pero si llamamos al `AudioStreamPlayer` mientras ya está reproduciendo un sonido, el nuevo sonido interrumpe al primero.

Un solución es programar una clase gestora global, auto-cargada. Ésta genera un "pool" de nodos `AudioStreamPlayer` que recorre a medida que llega cada nueva petición de efectos de sonido. Digamos que llamamos esa clase `Sound`, puedes usarla desde cualquier sitio en tu proyecto llamando a `Sound.play("coin_pickup.ogg")`. Esto soluciona el problema a corto plazo, pero causa más problemas:

1. **Estado global**: Un objeto es ahora responsable de todos los datos de los objetos. Si la clase `Sound` tiene errores o no tiene un `AudioStreamPlayer` disponible, todos los nodos que la llaman pueden fallar.

2. **Acceso global**: Ahora cualquier objeto puede llamar a `Sound.play(sound_path)` desde cualquier sitio, ya no hay una forma fácil de encontrar la fuente de un error.

3. **Asignación de recursos global**: Con un "pool" de nodos `AudioStreamPlayer` almacenado desde el principio, puedes tener muy pocos y enfrentarte a errores, o tener demasiados y usar más memoria de la necesaria.

Nota

Acerca del acceso global, el problema es que cualquier código en cualquier sitio podría pasar datos incorrectos al autoload `Sound` en nuestro ejemplo. Como resultado, el dominio a explorar para arreglar el error abarca todo el proyecto.

Cuando mantienes el código dentro de una escena, solo uno o dos scripts pueden estar involucrados en audio.

Compara esto con cada escena manteniendo tantos nodos `AudioStreamPlayer` como necesita dentro de sí y todos estos problemas desaparecen:

1. Cada escena gestiona su propia información de estado. Si hay un problema con los datos, únicamente causará problemas en esa escena.

2. Cada escena accede solo a sus propios nodos. Ahora, si hay un error, es fácil encontrar qué nodo es el culpable.

3. Cada escena asigna exactamente la cantidad de recursos que necesita.

### **_Gestionando funcionalidad o datos compartidos_**

Otra razón para usar un Autoload puede ser que quieras reutilizar el mismo método o dato en varias escenas.

En el caso de funciones, puedes crear un nuevo tipo de `Node` que proporcione esa característica para una escena individual usando la palabra clave [class_name](https://docs.godotengine.org/es/4.x/tutorials/scripting/gdscript/gdscript_basics.html#doc-gdscript-basics-class-name) en GDScript.

Cuando se trata de datos, puedes:

1. Crear un nuevo tipo de [Resource](https://docs.godotengine.org/es/4.x/classes/class_resource.html#class-resource) para compartir los datos.

2. Almacenar los datos en un objeto al que cada nodo tiene acceso. Por ejemplo, usado la propiedad `owner` para acceder al nodo raíz de la escena.

### **_Cuándo deberías usar un Autoload_**

GDScript soporta la creación de funciones `estáticas` utilizando `static func`. Combinado con `class_name`, permite crear bibliotecas de funciones de utilidad sin necesidad de crear una instancia para llamarlas. La limitación de las funciones estáticas es que estas no pueden acceder a variables miembro, funciones no estáticas o `self`.

Since Godot 4.1, GDScript also supports `static` variables using `static var`. This means you can now share variables across instances of a class without having to create a separate autoload.

Aún así, los nodos autocargados pueden simplificar tu código para sistemas con un amplio alcance. Si el singleton está gestionando su propia información sin invadir los datos de otros objetos, entonces es una manera estupenda de crear sistemas que manejen tareas de amplio alcance. Por ejemplo, un sistema de misiones o diálogos.

Nota

Un autoload no es exactamente un Singleton. Nada te impide instanciar copias de un nodo auto-cargado. Sólo es una herramienta que hace que un nodo se cargue automáticamente como un hijo de la raíz de tu árbol de escena, independientemente de la estructura de nodos de tu juego o de qué escenas ejecutes, p.ej. pulsando la tecla F6.

Como resultado, puedes acceder al nodo auto-cargado, por ejemplo un autoload llamado `Sound`, llamando a `get_node("/root/Sound")`.

## **Interfaces en Godot**

Frecuentemente se necesitan scripts que dependen de otros objetos para su funcionamiento. Hay 2 partes en este proceso:

1. Obtener una referencia al objeto que presumiblemente tenga las características.

2. Acceder a los datos o lógica desde el objeto.

El resto de este tutorial describe las distintas formas de hacer esto.

### **_Obteniendo referencias a objetos_**

Para todos los [Object](https://docs.godotengine.org/es/4.x/classes/class_object.html#class-object), el modo más básico de referenciarlos es obtener una referencia de un objeto existente desde otra instancia.

GDScriptC\#

var obj \= node.object \# Property access. var obj \= node.get_object() \# Method access.

Copiar al portapapeles

GodotObject obj \= node.Object; // Property access. GodotObject obj \= node.GetObject(); // Method access.

Copiar al portapapeles

El mismo principio aplica para objetos [RefCounted](https://docs.godotengine.org/es/4.x/classes/class_refcounted.html#class-refcounted). Mientras que los usuarios acceden normalmente a [Node](https://docs.godotengine.org/es/4.x/classes/class_node.html#class-node) y [Resource](https://docs.godotengine.org/es/4.x/classes/class_resource.html#class-resource) de este modo, hay modos alternativos disponibles.

En lugar de acceso mediante propiedades o métodos, se pueden obtener recursos por acceso de carga.

GDScriptC\#

\# If you need an "export const var" (which doesn't exist), use a conditional \# setter for a tool script that checks if it's executing in the editor. \# The \`@tool\` annotation must be placed at the top of the script. @tool

\# Load resource during scene load. var preres \= preload(path) \# Load resource when program reaches statement. var res \= load(path)

\# Note that users load scenes and scripts, by convention, with PascalCase \# names (like typenames), often into constants. const MyScene \= preload("my_scene.tscn") \# Static load const MyScript \= preload("my_script.gd")

\# This type's value varies, i.e. it is a variable, so it uses snake_case. @export var script_type: Script

\# Must configure from the editor, defaults to null. @export var const_script: Script: set(value): if Engine.is_editor_hint(): const_script \= value

\# Warn users if the value hasn't been set. func \_get_configuration_warnings(): if not const_script: return \["Must initialize property 'const_script'."\]

```
return \[\]
```

Copiar al portapapeles

// Tool script added for the sake of the "const \[Export\]" example. \[Tool\] public MyType { // Property initializations load during Script instancing, i.e. .new(). // No "preload" loads during scene load exists in C\#.

```
// Initialize with a value. Editable at runtime.
public Script MyScript \= GD.Load<Script\>("res://Path/To/MyScript.cs");

// Initialize with same value. Value cannot be changed.
public readonly Script MyConstScript \= GD.Load<Script\>("res://Path/To/MyScript.cs");

// Like 'readonly' due to inaccessible setter.
// But, value can be set during constructor, i.e. MyType().
public Script MyNoSetScript { get; } \= GD.Load<Script\>("res://Path/To/MyScript.cs");

// If need a "const \[Export\]" (which doesn't exist), use a
// conditional setter for a tool script that checks if it's executing
// in the editor.
private PackedScene \_enemyScn;

\[Export\]
public PackedScene EnemyScn
{
    get { return \_enemyScn; }
    set
    {
        if (Engine.IsEditorHint())
        {
            \_enemyScn \= value;
        }
    }
};

// Warn users if the value hasn't been set.
public string\[\] \_GetConfigurationWarnings()
{
    if (EnemyScn \== null)
    {
        return \["Must initialize property 'EnemyScn'."\];
    }
    return \[\];
}
```

}

Copiar al portapapeles

Nota lo siguiente:

1. Existen muchas formas en las que un lenguaje puede cargar tales recursos.

2. Al diseñar cómo los objetos accederán a los datos, no olvides que también se pueden pasar recursos como referencias.

3. Ten en mente que al cargar un recurso se obtiene la versión cacheada de la instancia del recurso mantenida por el motor. Para obtener uno nuevo, se debe [duplicate](https://docs.godotengine.org/es/4.x/classes/class_resource.html#class-resource-method-duplicate) (duplicar) una referencia existente o instanciar una nueva con `new()`.

Los nodos también tienen un punto de acceso alternativo: el SceneTree.

GDScriptC\#

extends Node

\# Slow. func dynamic_lookup_with_dynamic_nodepath(): print(get_node("Child"))

\# Faster. GDScript only. func dynamic_lookup_with_cached_nodepath(): print($Child)

\# Fastest. Doesn't break if node moves later. \# Note that \`@onready\` annotation is GDScript-only. \# Other languages must do... \# var child \# func \_ready(): \# child \= get_node("Child") @onready var child \= $Child func lookup_and_cache_for_future_access(): print(child)

\# Fastest. Doesn't break if node is moved in the Scene tree dock. \# Node must be selected in the inspector as it's an exported property. @export var child: Node func lookup_and_cache_for_future_access(): print(child)

\# Delegate reference assignment to an external source. \# Con: need to perform a validation check. \# Pro: node makes no requirements of its external structure. \# 'prop' can come from anywhere. var prop func call_me_after_prop_is_initialized_by_parent(): \# Validate prop in one of three ways.

```
\# Fail with no notification.
if not prop:
	return

\# Fail with an error message.
if not prop:
	printerr("'prop' wasn't initialized")
	return

\# Fail and terminate.
\# NOTE: Scripts run from a release export template don't run \`assert\`s.
assert(prop, "'prop' wasn't initialized")
```

\# Use an autoload. \# Dangerous for typical nodes, but useful for true singleton nodes \# that manage their own data and don't interfere with other objects. func reference_a_global_autoloaded_variable(): print(globals) print(globals.prop) print(globals.my_getter())

Copiar al portapapeles

using Godot; using System; using System.Diagnostics;

public class MyNode : Node { // Slow public void DynamicLookupWithDynamicNodePath() { GD.Print(GetNode("Child")); }

```
// Fastest. Lookup node and cache for future access.
// Doesn't break if node moves later.
private Node \_child;
public void \_Ready()
{
    \_child \= GetNode("Child");
}
public void LookupAndCacheForFutureAccess()
{
    GD.Print(\_child);
}

// Delegate reference assignment to an external source.
// Con: need to perform a validation check.
// Pro: node makes no requirements of its external structure.
//      'prop' can come from anywhere.
public object Prop { get; set; }
public void CallMeAfterPropIsInitializedByParent()
{
    // Validate prop in one of three ways.

    // Fail with no notification.
    if (prop \== null)
    {
        return;
    }

    // Fail with an error message.
    if (prop \== null)
    {
        GD.PrintErr("'Prop' wasn't initialized");
        return;
    }

    // Fail with an exception.
    if (prop \== null)
    {
        throw new InvalidOperationException("'Prop' wasn't initialized.");
    }

    // Fail and terminate.
    // Note: Scripts run from a release export template don't run \`Debug.Assert\`s.
    Debug.Assert(Prop, "'Prop' wasn't initialized");
}

// Use an autoload.
// Dangerous for typical nodes, but useful for true singleton nodes
// that manage their own data and don't interfere with other objects.
public void ReferenceAGlobalAutoloadedVariable()
{
    MyNode globals \= GetNode<MyNode\>("/root/Globals");
    GD.Print(globals);
    GD.Print(globals.Prop);
    GD.Print(globals.MyGetter());
}
```

};

Copiar al portapapeles

### **_Acceso a datos o lógica desde un objeto_**

El API de scripting de Godot es tipado dinámico (duck-typed). Esto quiere decir que si un script ejecuta una operación, Godot no valida si soporta la operación por **tipo**. En su lugar chequea que el objeto **implemente** el método individual.

Por ejemplo, la clase [CanvasItem](https://docs.godotengine.org/es/4.x/classes/class_canvasitem.html#class-canvasitem) tiene la propiedad `visible`. Todas las propiedades expuestas al API de scripting son en efecto un par setter y getter vinculados a un nombre. Si uno intenta acceder a [CanvasItem.visible](https://docs.godotengine.org/es/4.x/classes/class_canvasitem.html#class-canvasitem-property-visible), entonces Godot hará los siguientes chequeos en orden:

- Si el objeto tiene un script adjunto, intentará establecer la propiedad a través del script. Esto deja abierta la oportunidad de que los scripts anulen una propiedad definida en un objeto base al anular el método setter de la propiedad.

- Si el script no tiene la propiedad, realiza una búsqueda en el HashMap de la ClassDB en busca de la propiedad "visible", contra la clase CanvasItem y todos sus tipos heredados. Si la encuentra, este llamará al setter o getter vinculado. Para más información acerca de HashMaps, ver [data preferences](https://docs.godotengine.org/es/4.x/tutorials/best_practices/data_preferences.html#doc-data-preferences).

- Si no se encuentra, realiza una comprobación explícita para ver si el usuario desea acceder a las propiedades "script" o "meta".

- Si no es así, busca una implementación `_set`/`_get` (dependiendo del tipo de acceso) en el CanvasItem y sus tipos heredados. Estos métodos pueden ejecutar una lógica que da la impresión de que el objeto tiene una propiedad. Este es también el caso del método `_get_property_list`.

  - Ten en cuenta que esto sucede incluso con nombres de símbolos no permitidos, como nombres que empiezan por un número o que contienen una barra.

Como resultado, este sistema puede localizar una propiedad ya sea en el script, en la clase del objeto o en cualquier clase que el objeto herede, pero sólo para cosas que se extiendan en Object.

Godot proporciona una variedad de opciones para realizar comprobaciones de tiempo de ejecución en estos accesos:

- Un acceso a propiedad en tipado dinámico. Estas harán chequeo de propiedades (como se describió anteriormente). Si la operación no está disponible por el objeto se detendrá la ejecución.

  GDScriptC\#

  \# All Objects have duck-typed get, set, and call wrapper methods. get_parent().set("visible", false)

  \# Using a symbol accessor, rather than a string in the method call, \# will implicitly call the \`set\` method which, in turn, calls the \# setter method bound to the property through the property lookup \# sequence. get_parent().visible \= false

  \# Note that if one defines a \_set and \_get that describe a property's \# existence, but the property isn't recognized in any \_get_property_list \# method, then the set() and get() methods will work, but the symbol \# access will claim it can't find the property.

  Copiar al portapapeles

  // All Objects have duck-typed Get, Set, and Call wrapper methods. GetParent().Set("visible", false);

  // C\# is a static language, so it has no dynamic symbol access, e.g. // \`GetParent().Visible \= false\` won't work.

  Copiar al portapapeles

- Un chequeo de método. En el caso de [CanvasItem.visible](https://docs.godotengine.org/es/4.x/classes/class_canvasitem.html#class-canvasitem-property-visible), se puede acceder al método `set_visible` y `is_visible` como cualquier otro método.

  GDScriptC\#

  var child \= get_child(0)

  \# Dynamic lookup. child.call("set_visible", false)

  \# Symbol-based dynamic lookup. \# GDScript aliases this into a 'call' method behind the scenes. child.set_visible(false)

  \# Dynamic lookup, checks for method existence first. if child.has_method("set_visible"): child.set_visible(false)

  \# Cast check, followed by dynamic lookup. \# Useful when you make multiple "safe" calls knowing that the class \# implements them all. No need for repeated checks. \# Tricky if one executes a cast check for a user-defined type as it \# forces more dependencies. if child is CanvasItem: child.set_visible(false) child.show_on_top \= true

  \# If one does not wish to fail these checks without notifying users, \# one can use an assert instead. These will trigger runtime errors \# immediately if not true. assert(child.has_method("set_visible")) assert(child.is_in_group("offer")) assert(child is CanvasItem)

  \# Can also use object labels to imply an interface, i.e. assume it \# implements certain methods. \# There are two types, both of which only exist for Nodes: Names and \# Groups.

  \# Assuming... \# A "Quest" object exists and 1\) that it can "complete" or "fail" and \# that it will have text available before and after each state...

  \# 1\. Use a name. var quest \= $Quest print(quest.text) quest.complete() \# or quest.fail() print(quest.text) \# implied new text content

  \# 2\. Use a group. for a_child in get_children(): if a_child.is_in_group("quest"): print(quest.text) quest.complete() \# or quest.fail() print(quest.text) \# implied new text content

  \# Note that these interfaces are project-specific conventions the team \# defines (which means documentation\! But maybe worth it?). \# Any script that conforms to the documented "interface" of the name or \# group can fill in for it.

  Copiar al portapapeles

  Node child \= GetChild(0);

  // Dynamic lookup. child.Call("SetVisible", false);

  // Dynamic lookup, checks for method existence first. if (child.HasMethod("SetVisible")) { child.Call("SetVisible", false); }

  // Use a group as if it were an "interface", i.e. assume it implements // certain methods. // Requires good documentation for the project to keep it reliable // (unless you make editor tools to enforce it at editor time). // Note, this is generally not as good as using an actual interface in // C\#, but you can't set C\# interfaces from the editor since they are // language-level features. if (child.IsInGroup("Offer")) { child.Call("Accept"); child.Call("Reject"); }

  // Cast check, followed by static lookup. CanvasItem ci \= GetParent() as CanvasItem; if (ci \!= null) { ci.SetVisible(false);

```
// useful when you need to make multiple safe calls to the class
ci.ShowOnTop \= true;
```

}

// If one does not wish to fail these checks without notifying users, // one can use an assert instead. These will trigger runtime errors // immediately if not true. Debug.Assert(child.HasMethod("set_visible")); Debug.Assert(child.IsInGroup("offer")); Debug.Assert(CanvasItem.InstanceHas(child));

// Can also use object labels to imply an interface, i.e. assume it // implements certain methods. // There are two types, both of which only exist for Nodes: Names and // Groups.

// Assuming... // A "Quest" object exists and 1\) that it can "Complete" or "Fail" and // that it will have Text available before and after each state...

// 1\. Use a name. Node quest \= GetNode("Quest"); GD.Print(quest.Get("Text")); quest.Call("Complete"); // or "Fail". GD.Print(quest.Get("Text")); // Implied new text content.

// 2\. Use a group. foreach (Node AChild in GetChildren()) { if (AChild.IsInGroup("quest")) { GD.Print(quest.Get("Text")); quest.Call("Complete"); // or "Fail". GD.Print(quest.Get("Text")); // Implied new text content. } }

// Note that these interfaces are project-specific conventions the team // defines (which means documentation\! But maybe worth it?). // Any script that conforms to the documented "interface" of the // name or group can fill in for it. Also note that in C\#, these methods // will be slower than static accesses with traditional interfaces.

Copiar al portapapeles

- Externaliza el acceso a un [Callable](https://docs.godotengine.org/es/4.x/classes/class_callable.html#class-callable). Puedes resultar útil en casos en que se quiere maximizar el nivel de libertad de dependencias. En este caso se depende de un contexto externo para configurar el método.

GDScriptC\#

\# child.gd extends Node var fn \= null

func my_method(): if fn: fn.call()

\# parent.gd extends Node

@onready var child \= $Child

func \_ready(): child.fn \= print_me child.my_method()

func print_me(): print(name)

Copiar al portapapeles

// Child.cs using Godot;

public partial class Child : Node { public Callable? Callable { get; set; }

```
public void MyMethod()
{
    Callable?.Call();
}
```

}

// Parent.cs using Godot;

public partial class Parent : Node { private Child \_child;

```
public void \_Ready()
{
    \_child \= GetNode<Child\>("Child");
    \_child.Callable \= Callable.From(PrintMe);
    \_child.MyMethod();
}

public void PrintMe()
{
    GD.Print(Name);
}
```

}

Copiar al portapapeles

Estas estrategias contribuyen al diseño flexible de Godot. Entre todos ellos, los usuarios disponen de una amplia gama de herramientas para satisfacer sus necesidades específicas.

## [**Selección de tipos de datos**](https://docs.godotengine.org/es/4.x/tutorials/best_practices/data_preferences.html#data-preferences)

¿Alguna vez te has preguntado si se debería abordar el problema X con la estructura de datos Y o Z? Este artículo cubre una variedad de temas relacionados con estos dilemas.

Nota

Este artículo hace referencia a las operaciones de "tiempo-\[algo\]". Esta terminología proviene del análisis de algoritmos ' [Big O Notation](https://rob-bell.net/2009/06/a-beginners-guide-to-big-o-notation/).

En resumen, describe el peor de los casos de duración del tiempo de ejecución. En términos simples:

"A medida que aumenta el tamaño de un dominio problemático, la duración del tiempo de ejecución del algoritmo..."

- Tiempo-constante, `O(1)`: "...no aumenta."

- Tiempo-logarítmico, `O(log n)`: "...aumenta a un ritmo lento."

- Tiempo-lineal, `O(n)`: "...aumenta a la misma frecuencia."

- Etc.

Imagínate si tuvieras que procesar 3 millones de puntos de datos en un solo fotograma. Sería imposible crear esta característica con un algoritmo de tiempo-lineal, ya que el gran tamaño de los datos aumentaría el tiempo de ejecución mucho más allá del tiempo asignado. En cambio, un algoritmo de tiempo-constante podría realizar la operación sin problemas.

En general, los desarrolladores quieren evitar participar en operaciones de tiempo lineal tanto como sea posible. Pero, si uno mantiene la escala de una operación de tiempo lineal reducida, y no es necesario realizar la operación con frecuencia, entonces podría ser aceptable. Equilibrar estos requisitos y elegir el algoritmo y la estructura de datos adecuados para el trabajo es parte de lo que hace que las habilidades de los programadores sean valiosas.

### **_Array vs. Diccionario vs. Objeto_**

Godot almacena todas las variables del API de scripting en la clase [Variant](https://docs.godotengine.org/es/4.x/engine_details/architecture/variant_class.html#doc-variant-class). Las Variants pueden guardar estructuras de datos compatible con Variant como [Array](https://docs.godotengine.org/es/4.x/classes/class_array.html#class-array) y [Dictionary](https://docs.godotengine.org/es/4.x/classes/class_dictionary.html#class-dictionary) y también [Object](https://docs.godotengine.org/es/4.x/classes/class_object.html#class-object).

Godot implementa Arrays como `Vector<Variant>`. El motor almacena el contenido del Array en secciones contínuas de memoria, es decir, están adyacentes uno con el otro en fila.

Nota

Para los que no están familiarizados con C++, Vector es el nombre del objeto array en las bibliotecas tradicionales de C++. Se trata de un tipo de "plantilla", lo que significa que sus registros sólo pueden contener un tipo particular (indicado corchetes angulares). Así, por ejemplo, un [PackedStringArray](https://docs.godotengine.org/es/4.x/classes/class_packedstringarray.html#class-packedstringarray) sería algo así como un `Vector<String>`.

Los almacenes de memoria contiguos implican el siguiente rendimiento de la operación:

- **Iterate:** El más rápido. Ideal para loops.

  - Op: Lo único que hace es incrementar un contador para llegar al siguiente registro.

- **Insert, Erase, Move:** Depende de la posición. En general, es lento.

  - Op: Añadir/eliminar/mover contenido implica mover los registros adyacentes (para hacer espacio / ocupar espacio).

  - Añadir/eliminar rápidamente _desde el final_.

  - Añadir/eliminar lentamente _desde una posición arbitraria_.

  - Añadir/eliminar más lentamente _desde el frente_.

  - Si se hacen muchas inserciones/eliminaciones _desde el frente_, entonces...

    1. invertir el array.

    2. haz un bucle que ejecute los cambios del Array _al final_.

    3. reinvierte el array.

       Esto hace solo 2 copias del array (aun en tiempo constante, pero lento) en comparación a copiar alrededor de la mitad del array, en promedio, N veces (tiempo lineal).

- **Get, Set:** Más rápido _por posición_. Por ejemplo, puedes solicitar el registro 0º, 2º, 10º, etc., pero no puedes especificar qué registro deseas.

  - Op: Una operación de adición desde el comienzo del array hasta la posición del índice deseado.

- **Find:** El más lento. Identifica el índice/posición de un valor.

  - Op: Iterar a través del array y compara los valores hasta que encuentre una coincidencia.

    - El rendimiento también depende de si uno necesita una búsqueda exhaustiva o no.

  - Cuando se mantienen ordenadas, las operaciones de búsqueda personalizada pueden llegar a tiempo logarítmico (relativamente rápido). Sin embargo, los usuarios inexpertos no se sentirán cómodos con esto. Se hace reordenando el Array después de cada edición y escribiendo un algoritmo de búsqueda ordenado.

Godot implements Dictionary as a `HashMap<Variant, Variant, VariantHasher, StringLikeVariantComparator>`. The engine stores a small array (initialized to 2^3 or 8 records) of key-value pairs. When one attempts to access a value, they provide it a key. It then _hashes_ the key, i.e. converts it into a number. The "hash" is used to calculate the index into the array. As an array, the HM then has a quick lookup within the "table" of keys mapped to values. When the HashMap becomes too full, it increases to the next power of 2 (so, 16 records, then 32, etc.) and rebuilds the structure.

Los "Hashes" son para reducir la posibilidad de una colisión de llaves. Si se produce uno, la tabla debe recalcular otro índice para el valor que tenga en cuenta la posición anterior. En total, esto resulta en un acceso constante a todos los registros a expensas de la memoria y de una menor eficiencia operativa.

2. Hashing de cada clave un número arbitrario de veces.

   - Las operaciones Hash son constantes, así que incluso si un algoritmo debe hacer más de una, siempre y cuando el número de cálculos hash no dependa demasiado de la densidad de la tabla, las cosas se mantendrán rápidas. Lo que lleva a...

3. Manteniendo un tamaño siempre creciente para la tabla.

   - Los HashMaps mantienen espacios de memoria no utilizados intercalados en la tabla a propósito para reducir las colisiones de hash y mantener la velocidad de los accesos. Es por eso que aumenta constantemente en tamaño de forma exponencial en potencias de dos.

Como se puede ver, los Diccionarios se especializan en tareas que los Arrays no pueden realizar. A continuación se muestra un resumen general de sus detalles operativos:

- **Iterate:** Rápido.

  - Op: Iterar sobre el vector interno del mapa de hashes. Devuelve cada clave. Después, los usuarios utilizan la clave para saltar y devolver el valor deseado.

- **Insert, Erase, Move:** Más rápido.

  - Op: Hash de la clave devuelta. Realiza una operación de adición para buscar el valor apropiado (inicio del array \+ offset). El desplazamiento consta de dos de estos dos pasos (uno para insertar y otro para borrar). El mapa debe hacer algún tipo de mantenimiento para conservar sus capacidades:

    - actualización ordenada de la Lista de registros.

    - determinará si la densidad de las tablas requiere ampliar la capacidad de las mismas.

  - El Diccionario recuerda en qué orden los usuarios insertaron sus claves. Esto le permite ejecutar iteraciones de forma segura.

- **Get, Set:** El más rápido. Igual que una búsqueda _por clave_.

  - Op: Igual que insertar/borrar/mover.

- **Find:** El más lento. Identifica la clave de un valor.

  - Op: Debe iterar a través de los registros y comparar el valor hasta que se encuentre una coincidencia.

  - Hay que tener en cuenta que Godot no proporciona esta característica out-of-the-box (porque no están pensados para esta tarea).

Godot implementa Objects como tontos, pero también como contenedores dinámicos de contenido de datos. Los objetos consultan las fuentes de datos cuando se plantean preguntas. Por ejemplo, para responder a la pregunta "¿tienes una propiedad llamada 'position'?", podría preguntar su [script](https://docs.godotengine.org/es/4.x/classes/class_script.html#class-script) o el [ClassDB](https://docs.godotengine.org/es/4.x/classes/class_classdb.html#class-classdb). Se puede encontrar más información sobre qué son los objetos y cómo funcionan en el artículo [Aplicando los principios orientados a objetos en Godot](https://docs.godotengine.org/es/4.x/tutorials/best_practices/what_are_godot_classes.html#doc-what-are-godot-classes).

El detalle importante aquí es la complejidad de la tarea del Object. Cada tiempo que performa una de esas consultas multi-source, este va a través de _muchos_ bucles iteración y búsquedas en HashMaps. Lo que es más, las consultas son operaciones lineales en el tiempo y dependen del tamaño de herencia del Object. Si la clase que consulta Object (clase actual) no encuentra nada, el pedido se difiere a la siguiente clase base hacia arriba hasta la clase Object original. Aunque esas operaciones sean realizadas rápidamente de manera aislada, la realidad es que se deben hacer muchas comprobaciones lo que las hace más lentas que las dos alternativas para buscar datos.

Nota

Cuando los desarrolladores mencionan lo lenta que es la API de scripting, se refieren a esta cadena de consultas. En comparación con el código C++ compilado, en el que la aplicación sabe exactamente dónde encontrar cualquier cosa, es inevitable que las operaciones de la API de secuencias de comandos tarden mucho más tiempo. Deben localizar la fuente de cualquier dato relevante antes de intentar acceder a ella.

La razón por la cual GDScript es lento es porque cada operación que realiza pasa a través de este sistema.

C\# puede procesar parte de los contenidos a mayor velocidad mediante un bytecode más optimizado. Pero, si el script C\# llama al contenido de una clase de motor o si el script intenta acceder a algo externo a él, pasará por este proceso.

NativeScript C++ va aún más lejos y mantiene todo interno por defecto. Las llamadas a estructuras externas pasarán por la API de scripting. En NativeScript C++, el registro de métodos para exponerlos a la API de scripting es una tarea manual. Es en este punto donde las clases externas, que no son de tipo C++, utilizarán la API para localizarlas.

Por lo tanto, asumiendo que uno se extiende desde Reference para crear una estructura de datos, como un Array o un Dictionary, ¿por qué elegir un Object en lugar de las otras dos opciones?

1. **Control:** Con objetos se tiene la capacidad de crear estructuras más sofisticadas. Se pueden realizar abstracciones en capas sobre los datos para asegurar que la API externa no cambie en respuesta a los cambios en la estructura de los datos internos. Además, los objetos pueden tener señales, lo que permite un comportamiento reactivo.

2. **Claridad:** Los objetos son una fuente de datos confiable cuando se trata de los datos que los scripts y las clases de motor definen para sí mismos. Las propiedades pueden no tener los valores que uno espera, pero uno no necesita preocuparse de si la propiedad existe en primer lugar.

3. **Conveniencia:** Si ya se tiene una estructura de datos similar en mente, entonces extenderse desde una clase existente hace que la tarea de construir la estructura de datos sea mucho más fácil. En comparación, los Arrays y Diccionarios no satisfacen todos los casos de uso que uno pueda tener.

Los objetos también ofrecen a los usuarios la oportunidad de crear estructuras de datos aún más especializadas. De esta forma, uno puede diseñar su propia List, Binary Search Tree, Heap, Splay Tree, Graph, Disjoint Set, y cualquier otra opción.

"¿Por qué no usar Node para estructuras de árbol?", uno podría preguntarse. Bueno, la clase Node contiene cosas que no serán relevantes para la estructura de datos personalizada de cada quien. Como tal, puede ser útil construir un tipo de nodo propio al construir estructuras de árbol.

GDScriptC\#

extends Object class_name TreeNode

var \_parent: TreeNode \= null var \_children := \[\]

func \_notification(p_what): match p_what: NOTIFICATION_PREDELETE: \# Destructor. for a_child in \_children: a_child.free()

Copiar al portapapeles

using Godot; using System.Collections.Generic;

// Can decide whether to expose getters/setters for properties later public partial class TreeNode : GodotObject { private TreeNode \_parent \= null;

```
private List<TreeNode\> \_children \= \[\];

public override void \_Notification(int what)
{
    switch (what)
    {
        case NotificationPredelete:
            foreach (TreeNode child in \_children)
            {
                node.Free();
            }
            break;
    }
}
```

}

Copiar al portapapeles

A partir de aquí, uno puede crear sus propias estructuras con características específicas, limitadas sólo por su imaginación.

### **_Enumeraciones: int vs. string_**

La mayoría de los idiomas ofrecen una opción de tipo de enumeración. GDScript no es diferente, pero a diferencia de la mayoría de los otros lenguajes, permite usar integers o strings para los valores enumerados (esto último sólamente cuando se utiliza la palabra clave `export` en GDScript). Entonces surge la pregunta, "¿Qué se debe usar?"

La respuesta corta es: "Con el que te sientas más cómodo". Esta es una característica específica de GDScript y no de Godot scripting en general; los lenguajes priorizan la usabilidad sobre el rendimiento.

A nivel técnico, las comparaciones entre enteros (tiempo-constante) serán más rápidas que las comparaciones entre strings (tiempo-lineal). Sin embargo, si uno quiere mantener las convenciones de otros idiomas, entonces debería usar enteros.

El problema principal con el uso de enteros surge cuando se quiere _imprimir_ el valor de un enum. Como enteros, al intentar imprimir `MY_ENUM` se imprimirá `5` o lo que sea, en lugar de algo como `"MyEnum"`. Para imprimir un enum de enteros, se tendría que escribir un Diccionary que mapee el valor de la cadena correspondiente para cada enum.

Si el propósito principal de usar una enumeración es para imprimir valores y uno desea agruparlos en conceptos relacionados, entonces tiene sentido usarlos como strings. De esta manera, no es necesaria una estructura de datos separada para ejecutar en la impresión.

### **_AnimatedTexture vs. AnimatedSprite2D vs. AnimationPlayer vs. AnimationTree_**

¿Bajo qué circunstancias se debe utilizar cada una de las clases de animación de Godot? La respuesta puede no ser muy clara para los nuevos usuarios de Godot.

[AnimatedTexture](https://docs.godotengine.org/es/4.x/classes/class_animatedtexture.html#class-animatedtexture) es una textura que el motor dibuja como un bucle animado en lugar de una imagen estática. Los usuarios pueden manipular...

1. la velocidad a la que se mueve a través de cada sección de la textura (FPS).

2. el número de regiones que contiene la textura (frames).

Godot's [RenderingServer](https://docs.godotengine.org/es/4.x/classes/class_renderingserver.html#class-renderingserver) entonces dibuja las regiones en secuencia a la tasa establecida. La buena noticia es que esto no implica ninguna lógica adicional por parte del motor. La mala noticia es que los usuarios tienen muy poco control.

Also note that AnimatedTexture is a [Resource](https://docs.godotengine.org/es/4.x/classes/class_resource.html#class-resource) unlike the other [Node](https://docs.godotengine.org/es/4.x/classes/class_node.html#class-node) objects discussed here. One might create a [Sprite2D](https://docs.godotengine.org/es/4.x/classes/class_sprite2d.html#class-sprite2d) node that uses AnimatedTexture as its texture. Or (something the others can't do) one could add AnimatedTextures as tiles in a [TileSet](https://docs.godotengine.org/es/4.x/classes/class_tileset.html#class-tileset) and integrate it with a [TileMapLayer](https://docs.godotengine.org/es/4.x/classes/class_tilemaplayer.html#class-tilemaplayer) for many auto-animating backgrounds that all render in a single batched draw call.

The [AnimatedSprite2D](https://docs.godotengine.org/es/4.x/classes/class_animatedsprite2d.html#class-animatedsprite2d) node, in combination with the [SpriteFrames](https://docs.godotengine.org/es/4.x/classes/class_spriteframes.html#class-spriteframes) resource, allows one to create a variety of animation sequences through spritesheets, flip between animations, and control their speed, regional offset, and orientation. This makes them well-suited to controlling 2D frame-based animations.

If one needs to trigger other effects in relation to animation changes (for example, create particle effects, call functions, or manipulate other peripheral elements besides the frame-based animation), then one will need to use an [AnimationPlayer](https://docs.godotengine.org/es/4.x/classes/class_animationplayer.html#class-animationplayer) node in conjunction with the AnimatedSprite2D.

AnimationPlayers también es la herramienta que uno necesita utilizar si se desea diseñar sistemas de animación 2D mas complejos, como…

1. **Animaciones cut-out :** editando las transformaciones de los sprites en el momento de la ejecución.

2. **Animaciones 2D en Mallas:** definiendo una región para la textura del sprite y riggeando un esqueleto a el. Luego se animan los huesos que estiran y curvan la textura en proporción a las relaciones entre los huesos.

3. Una mezcla de lo de arriba.

Mientras uno necesita un AnimationPlayer para diseñar cada una de las secuencias de animaciones para un juego, también puede ser util combinar animaciones para mezclar, por ejemplo, habilitando transiciones suaves entre estas animaciones. Tambien puede haber una estructura jerárquica entre las animaciones que uno planea para su objeto, Estos son los casos donde el [AnimationTree](https://docs.godotengine.org/es/4.x/classes/class_animationtree.html#class-animationtree) brilla. Uno puede encontrar una guía en profundidad en usar el AnimationTree en AnimationTree [aquí](https://docs.godotengine.org/es/4.x/tutorials/animation/animation_tree.html#doc-animation-tree).

## [**Recomendaciones de lógica**](https://docs.godotengine.org/es/4.x/tutorials/best_practices/logic_preferences.html#logic-preferences)

Alguna vez te has preguntado si uno debe enfocarse en un problema X con una estrategia Y o Z? Este articulo cubre una variedad de temas relacionados a estos dilemas.

### **_Agregar nodos y cambiar propiedades: ¿qué es lo primero?_**

Cuando se inicializan nodos de un script en tiempo de ejecución, puede que necesites cambiar propiedades como el nombre o la posición del nodo. Un dilema común es ¿cuándo deberías cambiar estos valores?

La mejor práctica es cambiar los valores de un nodo antes de añadirlo al árbol de escenas. Algunos setters de propiedades pueden tener código que actualizan otros valores relacionados y ese código puede ser lento. En la mayoría de los casos este código no tiene impacto en el desempeño del juego, pero en ciertos casos de uso como generación procedural, puede relentizar mucho tu juego.

For these reasons, it is usually best practice to set the initial values of a node before adding it to the scene tree. There are some exceptions where values _can't_ be set before being added to the scene tree, like setting global position.

### **_Cargar (load) vs. pre-cargar (preload)_**

En GDScript, existe el método global [preload](https://docs.godotengine.org/es/4.x/classes/class_%40gdscript.html#class-gdscript-method-preload). El carga los recursos lo más rapido posible para cargar frontalmente las operaciones de "carga" y evitar el cargar recursos mientras se encuentra en medio del código que se considera sensitivo para el rendimiento.

Su contraparte, el metodo [load](https://docs.godotengine.org/es/4.x/classes/class_%40gdscript.html#class-gdscript-method-load), carga un recurso solo cuando este llega a la declaración de carga. Esto es, el va a cargar un recurso en su lugar, y puede causar ralentizamiento en el medio de procesos importantes. La función de `load()` también es un alias de [ResourceLoader.load(path)](https://docs.godotengine.org/es/4.x/classes/class_resourceloader.html#class-resourceloader-method-load) que es accesible a _todos_ los lenguajes de scripting.

Entonces, cuando el precargar exactamente ocurre versus el cargar, y cuando uno debería de usar cualquiera de los dos? veamos un ejemplo:

GDScriptC\#C++

\# my_buildings.gd extends Node

\# Note how constant scripts/scenes have a different naming scheme than \# their property variants.

\# This value is a constant, so it spawns when the Script object loads. \# The script is preloading the value. The advantage here is that the editor \# can offer autocompletion since it must be a static path. const BuildingScn \= preload("res://building.tscn")

\# 1\. The script preloads the value, so it will load as a dependency \# of the 'my_buildings.gd' script file. But, because this is a \# property rather than a constant, the object won't copy the preloaded \# PackedScene resource into the property until the script instantiates \# with .new().

#

\# 2\. The preloaded value is inaccessible from the Script object alone. As \# such, preloading the value here actually does not benefit anyone.

#

\# 3\. Because the user exports the value, if this script stored on \# a node in a scene file, the scene instantiation code will overwrite the \# preloaded initial value anyway (wasting it). It's usually better to \# provide null, empty, or otherwise invalid default values for exports.

#

\# 4\. It is when one instantiates this script on its own with .new() that \# one will load "office.tscn" rather than the exported value. @export var a_building : PackedScene \= preload("office.tscn")

\# Uh oh\! This results in an error\! \# One must assign constant values to constants. Because \`load\` performs a \# runtime lookup by its very nature, one cannot use it to initialize a \# constant. const OfficeScn \= load("res://office.tscn")

\# Successfully loads and only when one instantiates the script\! Yay\! var office_scn \= load("res://office.tscn")

Copiar al portapapeles

using Godot;

// C\# and other languages have no concept of "preloading". public partial class MyBuildings : Node { //This is a read-only field, it can only be assigned when it's declared or during a constructor. public readonly PackedScene Building \= ResourceLoader.Load\<PackedScene\>("res://building.tscn");

```
public PackedScene ABuilding;

public override void \_Ready()
{
    // Can assign the value during initialization.
    ABuilding \= GD.Load<PackedScene\>("res://Office.tscn");
}
```

}

Copiar al portapapeles

using namespace godot;

class MyBuildings : public Node { GDCLASS(MyBuildings, Node)

public: const Ref\<PackedScene\> building \= ResourceLoader::get_singleton()-\>load("res://building.tscn"); Ref\<PackedScene\> a_building;

```
virtual void \_ready() override {
	// Can assign the value during initialization.
	a\_building \= ResourceLoader::get\_singleton()\->load("res://office.tscn");
}
```

};

Copiar al portapapeles

Precargar permite al script manejar toda la carga en el momento en que uno lee el script. Precargar es util, pero hay tambien tiempos donde uno no lo desea. Para distinguir entre estas situaciones, hay algunas cosas que uno puede considerar:

1. Si no se puede determinar cuándo el script podría cargarse, entonces precargar un recurso, especialmente una escena o script, puede resultar en más cargas que no son esperadas. Esto puede llevar a unos tiempo de carga variables no intencionales por sobre de las operaciones de carga originales.

2. Si algo puede reemplazar el valor (como la inicialización de una escena exportada), entonces precargar el valor no tiene sentido. Este punto no es un factor significante si uno quiere crear siempre los scripts.

3. Si uno sólo desea 'importar' otro recurso de clase (script o escena), entonces usar una constante precargada es a menudo el mejor curso de acción. Sin embargo, en casos excepcionales, es posible que no desee hacer esto:

   1. Si la clase 'importada' es capaz de ser modificada, entonces debería ser una propiedad, inicializada ya sea con un `export` o un `load()` (y tal vez no inicializada sino más adelante).

   2. Si el script posee demasiadas dependencias y no se quiere consumir mucha memoria, entonces lo deseable sería cargar y liberar dependencias en tiempo de ejecución según la circunstancia. Si se precargan recursos en constantes, entonces el único modo de liberar esos recursos será liberar el script por completo. Pero si son propiedades cargadas, entonces se las puede colocar en `null` y remover todas las referencias al recurso por completo (el que, como un tipo que extiende [RefCounted](https://docs.godotengine.org/es/4.x/classes/class_refcounted.html#class-refcounted), causará que los recursos se remuevan solos de memoria).

### **_Niveles grandes: estático vs dinámico_**

¿Si se está creando un nivel muy grande, cuáles son las circunstancias más apropiadas? ¿Se debería crear el nivel como un espacio estático? ¿O debería cargarse el nivel en partes y cambiar el contenido del mundo a medida se requiera?

Bien, la respuesta simple es "cuando la performance lo requiera". El dilema asociado con las dos opciones es una de las viejas opciones de programación: se optimiza memoria por sobre velocidad o viceversa?

La respuesta inexperta es de usar un nivel estático que cargue todo de una vez pero, dependiendo del proyecto, esto puede consumir una gran cantidad de memoria. El desperdicio de la RAM de los usuario hace que los programas comiencen a funcionar más lento o directamente cuelgues de cualquier otra cosa que la computadora esté tratando de ejecutar al mismo tiempo.

Sin importar qué, se debe romper escenas largas en otras más pequeñas (para ayudar en la reusabilidad de contenido). Los desarrolladores pueden entonces designar un nodo que manipule la creación/carga y borrado/descarga de recursos y nodos en tiempo real. Juegos con gra variedad y tamaño de entornos o elementos generados proceduralmente normalmente emplean esas estrategias para evitar desperdiciar memoria.

Por el otro lado, crear un sistema dinámico es más complejo, por ejemplo, utiliza mucha más lógica programada lo que resulta en oportunidades de errores y otros problemas. Si no se tiene cuidado, pueden desarrollar un sistema que agranda la deuda técnica de la aplicación.

Como tales, las mejores opciones serían...

1. Usar niveles estáticos para juegos pequeños.

2. Si se tiene tiempo/recursos en un juego mediano/largo, crea una biblioteca o plugin que pueda administrar nodos y recursos. Si se mejora con el tiempo, tanto para mejorar usabilidad como estabilidad, entonces puede evolucionar en una buena herramienta para usar en otros proyectos.

3. Programar la lógica dinámica para un juego mediano/grande porque se poseen las habilidades de programación, pero no el tiempo o recursos para refinar el código (el juego debe completarse). Puedes realizarse un refactor más adelante para colocar código en un plugin externo.

## [**Organización del proyecto**](https://docs.godotengine.org/es/4.x/tutorials/best_practices/project_organization.html#project-organization)

### **_Introducción_**

Como Godot no tiene restricciones en la estructura del proyecto o el uso del sistema de archivos, organizar los archivos mientras se aprende a usar el motor puede ser exigente. Este tutorial sugiere un modo de trabajo que será bueno como punto de partida. También se cubre el caso de control de versiones con Godot.

### **_Organización_**

Godot es basado en escenas por naturaleza, y usa el sistema de archivos como tal, sin metadatos o una base de datos de recursos.

A diferencia de otros motores, muchos recursos son contenidos en la escena misma, así que la cantidad de archivos es considerablemente menor.

Considerando eso, el enfoque más común es agrupar los recursos cerca de las escenas así, cuando el proyecto crece, se hace más manejable.

Como ejemplo, normalmente puedes ubicar en una sola carpeta los recursos básicos, como imágenes, mallas de modelos 3D, materiales, música, etc. y utilizar una carpeta separada para almacenar los niveles construidos que los usan.

/project.godot /docs/.gdignore \# See "Ignoring specific folders" below /docs/learning.html /models/town/house/house.dae /models/town/house/window.png /models/town/house/door.png /characters/player/cubio.dae /characters/player/cubio.png /characters/enemies/goblin/goblin.dae /characters/enemies/goblin/goblin.png /characters/npcs/suzanne/suzanne.dae /characters/npcs/suzanne/suzanne.png /levels/riverdale/riverdale.scn

Copiar al portapapeles

### **_Guía de estilo_**

Para que haya coherencia entre los proyectos, recomendamos seguir estas directrices:

4. Usa **snake_case** para los nombres de carpetas y archivos (con la excepción de los scripts C\#). Esto evita los problemas de sensibilidad a las mayúsculas y minúsculas que pueden surgir después de exportar un proyecto a Windows. Los scripts de C\# son una excepción a esta regla, ya que la convención es nombrarlos después del nombre de la clase que debe estar en PascalCase.

5. Usa **PascalCase** para los nombres de los nodos, ya que esto coincide con la carcasa del nodo incorporado.

6. En general, mantén los recursos de terceros en una carpeta `addons/` de nivel superior, aunque no sean plugins de edición. Esto facilita el seguimiento de los archivos de terceros. Hay algunas excepciones a esta regla; por ejemplo, si utilizas recursos de juego de terceros para un personaje, tiene más sentido incluirlos dentro de la misma carpeta que las escenas y los scripts del personaje.

### **_Importando_**

La versión de Godot anterior a la 3.0 hacía el proceso de importación de archivos fuera del proyecto. Aunque esto puede ser útil en proyectos de gran tamaño, ha resultado ser una molestia en la organización del proyecto para la mayoría de los desarrolladores.

A razón de esto, los recursos ahora son importados desde dentro de la carpeta del proyecto, transparentemente.

#### **Ignorando carpetas específicas**

Para evitar que Godot importe archivos contenidos en una carpeta específica, cree un archivo vacío llamado `.gdignore` en la carpeta (se requiere el \`\` .\`\` inicial). Esto puede ser útil para acelerar la importación inicial del proyecto.

Nota

Para crear un archivo que inicia con punto en Windows, coloca un punto al inicio y al final del archivo (".gdignore."). Windows removerá automaticamente el punto al final cuando confirmes el nombre.

Para crear un archivo cuyo nombre empiece con un punto en Windows, puedes usar un editor de texto como Notepad++ o usar el siguiente comando en el símbolo del sistema: `type nul > .gdignore`

Una vez que se ignora una carpeta, los recursos en esa carpeta ya no se pueden cargar utilizando los métodos `load()` y `preload()`. Ignorar una carpeta también la ocultará automáticamente en el panel del Sistema de Archivos (FileSystem dock), lo cual puede ser útil para reducir el desorden.

Cabe destacar que el contenido del archivo `.gdignore` es ignorado, por lo que este archivo debe estar vacío. No admite patrones como lo hacen los archivos `.gitignore`.

#### **Sensibilidad a mayúsculas**

Windows y recientes versiones de macOS usan sistemas de archivos no sensibles a mayúsculas por defecto, mientras que las distribuciones Linux usan un sistema de archivos sensible a mayúsculas por defecto. Esto puede causar problemas al exporta run proyecto ya que el sistema de archivos virtual de Godot, PCK, es sensible a mayúscylas. Para prevenir esto, es recomendado apegarse a un `snake_case` al nombrar todos los archivos del proyecto (y en minúsculas en general).

Nota

Puedes romper esta regla cuando la guia de estilos diga lo contrario (como la guía de estilos de C\#). Aún así, mantente consistente para evitar errores.

On Windows 10, to further avoid mistakes related to case sensitivity, you can also make the project folder case-sensitive. After enabling the Windows Subsystem for Linux feature, run the following command in a PowerShell window:

\# To enable case-sensitivity: fsutil file setcasesensitiveinfo \<path to project folder\> enable

\# To disable case-sensitivity: fsutil file setcasesensitiveinfo \<path to project folder\> disable

Copiar al portapapeles

If you haven't enabled the Windows Subsystem for Linux, you can enter the following line in a PowerShell window _running as Administrator_ then reboot when asked:

Enable-WindowsOptionalFeature \-Online \-FeatureName Microsoft-Windows-Subsystem-Linux

## **Sistemas de Control de Versiones**

### **_Introducción_**

Godot intenta ser amigable a VCS y genera mayormente archivos legibles y combinables.

### **_Plugins de control de versiones_**

Godot además soporta el uso de sistemas de control de versiones desde el editor mismo. Sin embargo, el control de versiones en el editor requiere de un plugin específico para el VCS que se está usando.

A partir de Julio de 2023, solo hay un plugin de Git disponible, pero la comunidad puede crear plugins de VCS (Sistemas de Control de Versiones) adicionales.

#### **Plugin Git oficial**

El uso de Git desde el editor está soportado con un plugin oficial. Puedes encontrar las versiones más recientes en [GitHub](https://github.com/godotengine/godot-git-plugin/releases).

La documentación sobre cómo utilizar el plugin de Git puede encontrarse en su [wiki](https://github.com/godotengine/godot-git-plugin/wiki).

### **_Archivos a excluir del VCS_**

Nota

Esto enlista los archivos y carpetas que deberian ser ignorados en el control de versiones en Godot 4.1 y posteriores.

La Lista de archivos o carpetas que deben ser ignoradas del control de versiones en Godot 3.x y Godot 4.0 son **completamente** diferentes. Esto es importante, debido a que tanto Godot 3.x como Godot 4.0 pueden guardar credenciales sensibles en `export_presets.cfg` (a diferencia de Godot 4.1 y posteriores versiones).

Si estas usando Godot 3, revisa en su lugar la versión `3.5` en la pagina de documentación.

Cuando abres un proyecto en Godot por primera vez, el programa automáticamente crea algunos archivos y carpetas. Para evitar sobrecargar tu repositorio de control de versiones con datos generados, deberías añadirlos al archivo .gitignore:

- `.godot/`: Esta carpeta almacena diversos datos de caché del proyecto.

- `*.translation`: Esos son archivos binarios de [traducciones](https://docs.godotengine.org/es/4.x/tutorials/i18n/internationalizing_games.html#doc-internationalizing-games) importadas generadas desde archivos CSV.

Puedes hacer que el administrador de proyectos de Godot genere automáticamente metadatos para el control de versiones al crear un proyecto. Al elegir la opción **Git** se crean los archivos `.gitignore` y `.gitattributes` dentro de la carpeta raíz del proyecto:

Crear metadatos para el control de versiones en el cuadro de diálogo Proyecto Nuevo del administrador de proyectos

Crear metadatos para el control de versiones en el cuadro de diálogo **Proyecto Nuevo** del administrador de proyectos

En proyectos existentes, selecciona la menú **Proyecto** en la parte superior del editor, luego selecciona **Control de Versiones \> Generar Metadatos para el Control de Versiones**.

### **_Trabajar con Git en Windows_**

La mayoría de los clientes de Git para Windows están configurados con el `core.autocrlf` en `true`. Esto puede llevar a que los archivos sean marcados innecesariamente como modificados por Git debido a que sus terminaciones de línea se convierten automáticamente de LF a CRLF.

Es mejor configurar esta opción como:

git config \--global core.autocrlf input

Copiar al portapapeles

Al crear metadatos para el control de versiones utilizando el administrador de proyectos o el editor, se aplicarán automáticamente los saltos de líneas LF utilizando el archivo `.gitattributes`. En este caso, no necesitas cambiar la configuración de Git.

### **_Git LFS_**

Git LFS (Large File Storage) es una extensión de Git que permite manejar archivos de gran tamaño en tu repositorio. Reemplaza archivos grandes con punteros de texto dentro de Git, mientras almacena dichos archivos en un servidor remoto. Esto es útil para manejar assets grandes como texturas, audio, y modelos 3D, sin hinchar el tamaño de tu repositorio Git.
