const os = require('os');

const platform = os.platform();
const moduleName = 'Milky2018/mgstudio';

function pkg(path) {
  return `${moduleName}/${path}`;
}

const linkConfigs = [];

function addLinkConfig(packageName, linkFlags) {
  linkConfigs.push({
    package: packageName,
    link_flags: linkFlags,
  });
}

if (platform === 'darwin' || platform === 'linux') {
  const zlibLinkFlags = '-lz';
  const zlibLinkedPackages = [pkg('asset'), pkg('ui'), pkg('shader'), pkg('audio')];
  for (const packageName of zlibLinkedPackages) {
    addLinkConfig(packageName, zlibLinkFlags);
  }
}

if (platform === 'darwin') {
  const darwinWindowLinkFlags =
    '-framework AppKit -framework QuartzCore -framework Foundation -lobjc -Wl,-undefined,dynamic_lookup';

  addLinkConfig(pkg('window/windowing_native'), darwinWindowLinkFlags);
}

console.log(
  JSON.stringify({
    link_configs: linkConfigs,
  }),
);
