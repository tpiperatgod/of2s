package sink

import (
	"fmt"
	"io/ioutil"
	"net/http"

	"k8s.io/klog/v2"
)

func HelloWorld(w http.ResponseWriter, r *http.Request) {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		klog.Fatalln(err)
	}
	klog.Info(string(body))

	fmt.Fprintln(w, "Hello, world!")
}
