package main

import (
	"context"
	"reflect"

	"k8s.io/klog/v2"
	"main.go/offf-go/framework"
	"main.go/offf-go/plugin"
	"main.go/userfunction"
	pluginCustom "main.go/userfunction/plugins/plugin-custom"
)

func main() {
	ctx := context.Background()
	fwk, err := framework.NewFramework()
	if err != nil {
		klog.Exit(err)
	}
	fwk.RegisterPlugins(getLocalPlugins())
	if err := fwk.Register(ctx, userfunction.Sender); err != nil {
		klog.Exit(err)
	}
	if err := fwk.Start(ctx); err != nil {
		klog.Exit(err)
	}
}

func getLocalPlugins() map[string]plugin.Plugin {
	nilPlugins := map[string]plugin.Plugin{}
	localPlugins := map[string]plugin.Plugin{
		pluginCustom.Name: pluginCustom.New(),
	}

	if reflect.DeepEqual(localPlugins, nilPlugins) {
		return nil
	} else {
		return localPlugins
	}
}
