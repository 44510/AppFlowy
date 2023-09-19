import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/application/panes/panes_cubit/panes_cubit.dart';
import 'package:appflowy/workspace/application/panes/size_controller.dart';
import 'package:appflowy/workspace/presentation/home/home_layout.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/home/panes/panes_layout.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'flowy_pane.dart';

class FlowyPaneGroup extends StatelessWidget {
  final PaneNode node;
  final double groupWidth;
  final double groupHeight;
  final HomeLayout layout;
  final HomeStackDelegate delegate;
  const FlowyPaneGroup({
    super.key,
    required this.node,
    required this.groupWidth,
    required this.groupHeight,
    required this.layout,
    required this.delegate,
  });

  @override
  Widget build(BuildContext context) {
    if (node.children.isEmpty) {
      return MouseRegion(
        onEnter: (_) => context.read<PanesCubit>().setActivePane(node),
        child: FlowyPane(
          node: node,
          delegate: delegate,
          layout: layout,
          paneContext: context,
          size: Size(groupWidth, groupHeight),
        ),
      );
    }
    return SizedBox(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            key: ValueKey(node.paneId),
            children: [
              ...node.children.indexed
                  .map(
                    (indexNode) => ChangeNotifierProvider<PaneSizeController>(
                      create: (context) => node.sizeController,
                      builder: (context, widget) =>
                          Consumer<PaneSizeController>(
                        builder: (context, sizeController, child) {
                          final paneLayout = PaneLayout(
                            childPane: indexNode,
                            parentPane: node,
                            sizeController: sizeController,
                            parentPaneConstraints: constraints,
                          );
                          return Stack(
                            children: [
                              _resolveFlowyPanes(paneLayout, indexNode),
                              _resizeBar(
                                sizeController,
                                indexNode,
                                context,
                                paneLayout,
                              )
                            ],
                          );
                        },
                      ),
                    ),
                  )
                  .toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _resizeBar(
    PaneSizeController sizeController,
    (int, PaneNode) indexNode,
    BuildContext context,
    PaneLayout paneLayout,
  ) {
    return Positioned(
      left: paneLayout.childPaneLPosition,
      top: paneLayout.childPaneTPosition,
      child: MouseRegion(
        cursor: paneLayout.resizeCursorType,
        child: GestureDetector(
          dragStartBehavior: DragStartBehavior.down,
          onHorizontalDragUpdate: (details) => node.sizeController.resize(
            paneLayout.childPaneWidth,
            sizeController.flex,
            indexNode.$1,
            details.delta.dx,
          ),
          onVerticalDragUpdate: (details) => node.sizeController.resize(
            paneLayout.childPaneHeight,
            sizeController.flex,
            indexNode.$1,
            details.delta.dy,
          ),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: paneLayout.resizerWidth,
            height: paneLayout.resizerHeight,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
                left: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _resolveFlowyPanes(
    PaneLayout paneLayout,
    (int, PaneNode) indexNode,
  ) {
    return Positioned(
      left: paneLayout.childPaneLPosition,
      top: paneLayout.childPaneTPosition,
      child: SizedBox(
        width: paneLayout.childPaneWidth,
        height: paneLayout.childPaneHeight,
        child: FlowyPaneGroup(
          node: indexNode.$2,
          groupWidth: paneLayout.childPaneWidth,
          groupHeight: paneLayout.childPaneHeight,
          delegate: delegate,
          layout: layout,
        ),
      ),
    );
  }
}
