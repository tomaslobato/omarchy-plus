import QtQuick
import qs.Ui

BarWidget {
  id: root

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    // nf-fa-rotate. One arrow circling. Slightly under the bar's 13px icons.
    text: "\uF01E"
    fontSize: 11
    tooltipText: "Rotar pantalla"
    onPressed: function(b) {
      if (b !== Qt.LeftButton || !root.bar) return
      root.bar.run("/home/lobato/.local/bin/omarchy-rotate-display")
    }
  }
}
