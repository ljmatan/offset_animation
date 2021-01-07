import 'package:flutter/material.dart';
import 'package:offset_animation/items_controller.dart';
import 'package:offset_animation/painter.dart';

// Location model class
class ObjectMesaurements {
  Size size;
  Offset offset;
  bool enabled;

  ObjectMesaurements(
    this.size,
    this.offset,
    this.enabled,
  );
}

class ButtonWrapper extends StatefulWidget {
  final Function(ObjectMesaurements) addToList;

  ButtonWrapper({@required this.addToList});

  @override
  State<StatefulWidget> createState() {
    return _ButtonWrapperState();
  }
}

class _ButtonWrapperState extends State<ButtonWrapper> {
  // Key used to access widget size and offset
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        // Box variable used to get the size and offset of the widget
        final RenderBox box = _key.currentContext.findRenderObject();
        final Size size = box.size;
        final Offset offset = box.globalToLocal(Offset.zero);

        // Add measurements to parent class
        widget.addToList(ObjectMesaurements(size, offset * -1, true));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Update this with button widget and add key parameter
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.red.shade300),
      child: SizedBox(key: _key, height: 50, width: 50),
    );
  }
}

class Demo extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _DemoState();
  }
}

class _DemoState extends State<Demo> {
  // List containing measurements of all of the buttons
  List<ObjectMesaurements> _buttonLocationList = [];

  void _addButtonLocation(ObjectMesaurements value) =>
      _buttonLocationList.add(value);

  void _checkTap(details) {
    for (var location in _buttonLocationList) {
      // Add if eligible for reward clause
      if (location.enabled &&
          details.globalPosition.dx <=
              location.offset.dx + location.size.width &&
          details.globalPosition.dx >= location.offset.dx &&
          details.globalPosition.dy <=
              location.offset.dy + location.size.height &&
          details.globalPosition.dy > location.offset.dy) {
        // Disable tap for reward gesture
        location.enabled = false;

        // Add a widget to the screen
        ItemsController.add(details.localPosition);

        // Enable reward gesture on this button after 200ms
        Future.delayed(
          const Duration(milliseconds: 200),
          () => location.enabled = true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        child: Stack(
          children: [
            Positioned(
              bottom: 20,
              child: ButtonWrapper(addToList: _addButtonLocation),
            ),
            Positioned(
              bottom: 60,
              right: 20,
              child: ButtonWrapper(addToList: _addButtonLocation),
            ),
            Positioned(
              left: 60,
              top: 120,
              child: ButtonWrapper(addToList: _addButtonLocation),
            ),
            Center(child: ButtonWrapper(addToList: _addButtonLocation)),
            MovingObjects(),
            Container(color: Colors.transparent),
          ],
        ),
        onTapDown: (details) => _checkTap(details),
        onPanUpdate: (details) => _checkTap(details),
      ),
    );
  }
}

// Animated moving image object
class MovingObject extends StatefulWidget {
  final double beginX, beginY, screenWidth;

  MovingObject({
    @required this.beginX,
    @required this.beginY,
    @required this.screenWidth,
  });

  @override
  State<StatefulWidget> createState() {
    return _MovingObjectState();
  }
}

class _MovingObjectState extends State<MovingObject>
    with TickerProviderStateMixin {
  AnimationController _offsetController;
  Animation<double> _offsetX;
  Animation<double> _offsetY;
  Animation<double> _opacity;
  AnimationController _rotationController;
  Animation<double> _rotation;

  List<Offset> _offsetList = [];

  double get x =>
      _offsetX.value +
      ((widget.beginX < widget.screenWidth / 2 ? 1 : -1) *
          (_offsetController.value < 0.5
              ? _offsetController.value
              : 1 - _offsetController.value) *
          50);

  @override
  void initState() {
    super.initState();
    _offsetController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..addListener(() => setState(
          () => _offsetList.add(Offset(x + 20, _offsetY.value)),
        )); // On offset controller change add Offset object to LinePainter
    _offsetX = Tween<double>(
      begin: widget.beginX,
      end: widget.screenWidth / 2 - 20,
    ).animate(
      _offsetController,
    );
    _offsetY = Tween<double>(
      begin: widget.beginY,
      end: 25,
    ).animate(
      _offsetController,
    );
    _opacity = Tween<double>(begin: 1, end: 0).animate(_offsetController);

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // Loop rotation animation
          _rotationController.reset();
          _rotationController.forward();
        }
      });
    _rotation = Tween<double>(begin: 0, end: 360).animate(
      _rotationController,
    );

    _offsetController.forward();
    _rotationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_offsetList.isNotEmpty)
          Opacity(
            opacity: _opacity.value / 2,
            child: CustomPaint(painter: TrailPainter(_offsetList)),
          ),
        Opacity(
          opacity: _opacity.value * 3,
          child: Transform.translate(
            offset: Offset(x, _offsetY.value),
            child: RotationTransition(
              turns: AlwaysStoppedAnimation(_rotation.value / 360),
              child: Image.asset('assets/images/icons/money.png', width: 40),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _offsetController.dispose();
    _rotationController.dispose();
    super.dispose();
  }
}

// Stack with objects updated via stream
class MovingObjects extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MovingObjectsState();
  }
}

class _MovingObjectsState extends State<MovingObjects> {
  @override
  void initState() {
    super.initState();
    ItemsController.init();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: ItemsController.stream,
      initialData: ItemsController.items,
      builder: (context, items) => Stack(
        children: [
          for (var item in ItemsController.items)
            MovingObject(
              beginX: item.dx,
              beginY: item.dy,
              screenWidth: MediaQuery.of(context).size.width,
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    ItemsController.dispose();
    super.dispose();
  }
}
