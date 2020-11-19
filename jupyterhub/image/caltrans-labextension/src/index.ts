import {
  IRouter,
  JupyterFrontEnd,
  JupyterFrontEndPlugin,
} from '@jupyterlab/application';

import {ICommandPalette, MainAreaWidget} from '@jupyterlab/apputils';

import {URLExt} from '@jupyterlab/coreutils';

import {ILauncher} from '@jupyterlab/launcher';

import {IMainMenu} from '@jupyterlab/mainmenu';

import {IRenderMimeRegistry} from '@jupyterlab/rendermime';

import '../style/index.css';

const SOURCE = require('../welcome.md').default;

/**
 * Initialization data for the cityofla-labextension extension.
 */
const extension: JupyterFrontEndPlugin<void> = {
  id: 'cityofla-labextension',
  autoStart: true,
  requires: [
    ICommandPalette,
    ILauncher,
    IMainMenu,
    IRenderMimeRegistry,
    IRouter,
    JupyterFrontEnd.IPaths
  ],
  activate: (
    app: JupyterFrontEnd,
    palette: ICommandPalette,
    launcher: ILauncher,
    menu: IMainMenu,
    rendermime: IRenderMimeRegistry,
    router: IRouter,
    paths: JupyterFrontEnd.IPaths
  ) => {
    const { commands, shell } = app;

    // Add a help link for the best practices site.
    menu.helpMenu.addGroup(
      [
        {
          command: 'help:open',
          args: {
            text: 'City of LA Best Practices',
            url: 'https://cityoflosangeles.github.io/best-practices',
          },
        },
      ],
      1,
    );

    // Function to create the welcome page.
    // This is deliberately not restored, as
    // we only want to show it when directed
    // by the URL router.
    const createWelcomeWidget = () => {
      const content = rendermime.createRenderer('text/markdown');
      const model = rendermime.createModel({
        data: {'text/markdown': SOURCE},
      });
      void content.renderModel(model);
      content.addClass('cola-Welcome');
      const widget = new MainAreaWidget({content});
      widget.title.label = 'Welcome';
      return widget;
    };

    let widget: MainAreaWidget;

    let command = 'cityoflosangeles:welcome';
    commands.addCommand(command, {
      label: 'Open Los Angeles Welcome Page',
      execute: args => {
        if (!widget || widget.isDisposed) {
          widget = createWelcomeWidget();
        }
        shell.add(widget, 'main');

        // Possibly empty 'welcome' from the query string.
        const path = args['path'] as string || '';
        const search = args['search'] as string || '';
        const hash = args['hash'] as string || '';
        const query = URLExt.queryStringToObject(search);
        const welcome = 'welcome' in query;
        if (!welcome) {
          return;
        }
        delete query['welcome'];
        const url = path + URLExt.objectToQueryString(query) + hash;
        router.navigate(url);
      },
    });

    // Add a command palette item for showing the welcome page.
    palette.addItem({command, category: 'Help'});

    // Allow the welcome page to be triggered via a query parameter.
    router.register({
      command,
      pattern: /(\?welcome|\&welcome)($|&)/,
    });

    // Add a command to launch RStudio
    command = 'cityoflosangeles:launch-rstudio';
    commands.addCommand(command, {
      label: args => args['isLauncher'] ? 'RStudio' : 'Launch RStudio',
      iconClass: args => args['isLauncher'] ? 'cola-RStudio-icon': '',
      execute: () => {
        const url = URLExt.join(paths.urls.base, 'rstudio');
        window.open(url, '_blank', 'noopener');
      }
    });
    launcher.add({
      command,
      args: { isLauncher: true },
      category: 'Other'
    });
    palette.addItem({ command, category: 'RStudio' });

    // Add a command to launch RStudio
    command = 'cityoflosangeles:launch-shiny';
    commands.addCommand(command, {
      label: args => args['isLauncher'] ? 'Shiny' : 'Launch Shiny',
      iconClass: args => args['isLauncher'] ? 'cola-Shiny-icon': '',
      execute: () => {
        const url = URLExt.join(paths.urls.base, 'shiny');
        window.open(url, '_blank', 'noopener');
      }
    });
    launcher.add({
      command,
      args: { isLauncher: true },
      category: 'Other'
    });
    palette.addItem({ command, category: 'RStudio' });

    // Add a command to launch pgAdmin
    command = 'cityoflosangeles:launch-pgadmin';
    commands.addCommand(command, {
      label: args => args['isLauncher'] ? 'pgAdmin' : 'Launch pgAdmin',
      iconClass: args => args['isLauncher'] ? 'cola-PostgreSQL-icon': '',
      execute: () => {
        const url = URLExt.join(paths.urls.base, 'pgadmin/browser/#');
        window.open(url, '_blank', 'noopener');
      }
    });
    launcher.add({
      command,
      args: { isLauncher: true },
      category: 'Other'
    });
    palette.addItem({ command, category: 'pgAdmin' });
  }
};

export default extension;
