using Toybox.WatchUi;
using Toybox.System;

class ChooserMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    // function onSelect(menuItem) {
    // }
}

class ChooserMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => WatchUi.loadResource(Rez.Strings.MenuTitle) });

        addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.MenuVersion), null, "version", null));
        addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.MenuLicense), null, "license", null));
    }
}
