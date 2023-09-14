import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/application/panes/panes_cubit/panes_cubit.dart';
import 'package:appflowy/workspace/application/panes/size_controller.dart';
import 'package:appflowy/workspace/application/tabs/tabs.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:nanoid/nanoid.dart';

enum Direction { front, back }

class PanesService {
  PaneNode splitHandler(
    PaneNode node,
    String targetPaneId,
    ViewPB? view,
    Direction direction,
    Axis axis,
    void Function(PaneNode) activePane,
    PaneNode? fromNode,
  ) {
    /// This is a recursive handler, following condition checks if passed node
    /// is our target node
    if (node.paneId == targetPaneId) {
      ///we create a holder node which would replace current target and add
      ///target node + new node as its children
      final newNode = PaneNode(
        sizeController: PaneSizeController(flex: [0.5, 0.5]),
        paneId: nanoid(),
        children: const [],
        axis: axis,
        tabs: null,
      );
      final ret = newNode.copyWith(
        children: [
          node.copyWith(
            paneId: nanoid(),
            parent: newNode,
            sizeController: PaneSizeController.intial(),
            axis: null,
            tabs: Tabs(
              currentIndex: node.tabs.currentIndex,
              pageManagers: node.tabs.pageManagers,
            ),
          ),
          fromNode?.copyWith(paneId: nanoid()) ??
              PaneNode(
                sizeController: PaneSizeController.intial(),
                paneId: nanoid(),
                children: const [],
                parent: newNode,
                axis: null,
                tabs: Tabs(
                  pageManagers: [PageManager()..setPlugin(view!.plugin())],
                ),
              )
        ],
      );
      activePane(ret.children[0]);
      return ret;
    }

    /// if we haven't found our target node there is a possibility that our
    /// target node is a child of an already existing holder node, we do a quick lookup at children of current node, if we find target in children, we just append a new child at correct location and return
    if (node.axis == axis) {
      for (int i = 0; i < node.children.length; i++) {
        if (node.children[i].paneId == targetPaneId) {
          final newNode = fromNode?.copyWith(paneId: nanoid()) ??
              PaneNode(
                sizeController: PaneSizeController.intial(),
                paneId: nanoid(),
                children: const [],
                parent: node.parent,
                tabs: Tabs(
                  pageManagers: [PageManager()..setPlugin(view!.plugin())],
                ),
              );
          if (direction == Direction.front) {
            if (i == node.children.length) {
              node.children.add(newNode);
            } else {
              node.children.insert(i + 1, newNode);
            }
          } else {
            node.children.insert(i, newNode);
          }
          final ret = node.copyWith(
            paneId: nanoid(),
            sizeController: PaneSizeController(
              flex: List.generate(
                node.children.length,
                (_) => 1 / (node.children.length),
              ),
            ),
          );
          activePane(ret.children[i]);
          return ret;
        }
      }
    }

    ///if we couldn't find target in children of current node or if current
    ///node isn't right holder we proceed recursively to dfs remaining
    ///children
    final newChildren = node.children
        .map(
          (e) => splitHandler(
            e,
            targetPaneId,
            view,
            direction,
            axis,
            activePane,
            fromNode,
          ),
        )
        .toList();
    return node.copyWith(children: newChildren);
  }

  PaneNode closePaneHandler(
    PaneNode node,
    String targetPaneId,
    Function(PaneNode) setActiveNode,
  ) {
    if (node.paneId == targetPaneId) {
      return node;
    }
    for (final element in node.children) {
      if (element.paneId == targetPaneId) {
        node.children.remove(element);
        setActiveNode(node);
        if (node.children.length == 1) {
          setActiveNode(node.children.first);
          return node.children.first.copyWith(
            paneId: nanoid(),
            parent: node.parent,
          );
        }
        return node.copyWith(
          paneId: nanoid(),
          tabs: Tabs(
            currentIndex: node.tabs.currentIndex,
            pageManagers: node.tabs.pageManagers,
          ),
          sizeController: PaneSizeController(
            flex: List.generate(
              node.children.length,
              (_) => 1 / (node.children.length),
            ),
          ),
        );
      }
    }

    final newChildren = node.children.map((e) {
      return closePaneHandler(
        e,
        targetPaneId,
        setActiveNode,
      );
    }).toList();

    return node.copyWith(children: newChildren);
  }

  int countNodeHandler(PaneNode root) {
    if (root.children.isEmpty) {
      return 1;
    }
    int totalCount = 1;
    for (final child in root.children) {
      totalCount += countNodeHandler(child);
    }

    return totalCount;
  }
}
