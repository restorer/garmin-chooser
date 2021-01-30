using Toybox.WatchUi;
using Toybox.System;

class ChooserMenuDelegate extends WatchUi.MenuInputDelegate {
    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item) {
        if (item == :Item1) {
            System.println("Item 1");
        } else if (item == :Item2) {
            System.println("Item 2");
        }
    }
}
