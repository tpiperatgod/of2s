package runtime

import (
	"context"
	"net/http"

	"k8s.io/klog"
	"main.go/offf-go/plugin"

	cloudevents "github.com/cloudevents/sdk-go/v2"

	ofctx "main.go/offf-go/context"
)

type Interface interface {
	Start(ctx context.Context) error
	RegisterHTTPFunction(
		ctx ofctx.Context,
		prePlugins []plugin.Plugin,
		postPlugins []plugin.Plugin,
		fn func(http.ResponseWriter, *http.Request) error,
	) error
	RegisterOpenFunction(
		ctx ofctx.Context,
		prePlugins []plugin.Plugin,
		postPlugins []plugin.Plugin,
		fn func(ofctx.Context, []byte) (ofctx.Out, error),
	) error
	RegisterCloudEventFunction(
		ctx context.Context,
		funcContex ofctx.Context,
		prePlugins []plugin.Plugin,
		postPlugins []plugin.Plugin,
		fn func(context.Context, cloudevents.Event) error,
	) error
}

type RuntimeManager struct {
	FuncContext ofctx.Context
	PrePlugins  []plugin.Plugin
	PostPlugins []plugin.Plugin
	PluginState map[string]plugin.Plugin
}

func NewRuntimeManager(funcContext ofctx.Context, prePlugin []plugin.Plugin, postPlugin []plugin.Plugin) *RuntimeManager {
	ctx := funcContext
	return &RuntimeManager{
		FuncContext: ctx,
		PrePlugins:  prePlugin,
		PostPlugins: postPlugin,
	}
}

func (rm *RuntimeManager) Init() {
	rm.PluginState = map[string]plugin.Plugin{}

	var newPrePlugins []plugin.Plugin
	for _, plg := range rm.PrePlugins {
		if existPlg, ok := rm.PluginState[plg.Name()]; !ok {
			p := plg.Init()
			rm.PluginState[plg.Name()] = p
			newPrePlugins = append(newPrePlugins, p)
		} else {
			newPrePlugins = append(newPrePlugins, existPlg)
		}
	}
	rm.PrePlugins = newPrePlugins

	var newPostPlugins []plugin.Plugin
	for _, plg := range rm.PostPlugins {
		if existPlg, ok := rm.PluginState[plg.Name()]; !ok {
			p := plg.Init()
			rm.PluginState[plg.Name()] = p
			newPostPlugins = append(newPostPlugins, p)
		} else {
			newPostPlugins = append(newPostPlugins, existPlg)
		}
	}
	rm.PostPlugins = newPostPlugins
}

func (rm *RuntimeManager) ProcessPreHooks() {
	for _, plg := range rm.PrePlugins {
		if err := plg.ExecPreHook(rm.FuncContext, rm.PluginState); err != nil {
			klog.Warningf("plugin %s failed in pre phase: %s", plg.Name(), err.Error())
		}
	}
}

func (rm *RuntimeManager) ProcessPostHooks() {
	for _, plg := range rm.PostPlugins {
		if err := plg.ExecPostHook(rm.FuncContext, rm.PluginState); err != nil {
			klog.Warningf("plugin %s failed in post phase: %s", plg.Name(), err.Error())
		}
	}
}
