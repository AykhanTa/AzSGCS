function Component()
{

}

Component.prototype.createOperations = function()
{
    try {
        component.createOperations();
    } catch (e) {
        console.log(e);
    }

    if (systemInfo.productType === "windows") {
        component.addOperation("CreateShortcut", "@TargetDir@/bin/AzShieldGCS.exe", "@StartMenuDir@/AzShieldGCS.lnk");
        component.addOperation("CreateShortcut", "@TargetDir@/bin/AzShieldGCS.exe", "@DesktopDir@/AzShieldGCS.lnk");
    }
}
