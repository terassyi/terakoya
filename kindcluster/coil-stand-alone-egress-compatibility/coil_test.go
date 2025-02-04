package main

import (
	"errors"
	"fmt"
	"time"

	coilv2 "github.com/cybozu-go/coil/v2/api/v2"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	corev1 "k8s.io/api/core/v1"
)

var _ = Describe("Coil", func() {
	It("should check health probe for coil-{ipam,egress}-controller", func() {
		By("checking coil-ipam-controller pods get ready")
		Eventually(func(g Gomega) error {
			pods := &corev1.PodList{}
			err := getResource("kube-system", "pods", "", "app.kubernetes.io/component=coil-ipam-controller", pods)
			if err != nil {
				return err
			}

			if len(pods.Items) == 0 {
				return errors.New("bug")
			}

		OUTER:
			for _, pod := range pods.Items {
				for _, cond := range pod.Status.Conditions {
					if cond.Type != corev1.PodReady {
						continue
					}
					if cond.Status == corev1.ConditionTrue {
						continue OUTER
					}
				}
				return fmt.Errorf("pod is not ready: %s", pod.Name)
			}

			return nil
		}).Should(Succeed())

		By("checking coil-egress-controller pods get ready")
		Eventually(func(g Gomega) error {
			pods := &corev1.PodList{}
			err := getResource("kube-system", "pods", "", "app.kubernetes.io/component=coil-egress-controller", pods)
			if err != nil {
				return err
			}

			if len(pods.Items) == 0 {
				return errors.New("bug")
			}

		OUTER:
			for _, pod := range pods.Items {
				for _, cond := range pod.Status.Conditions {
					if cond.Type != corev1.PodReady {
						continue
					}
					if cond.Status == corev1.ConditionTrue {
						continue OUTER
					}
				}
				return fmt.Errorf("pod is not ready: %s", pod.Name)
			}

			return nil
		}).Should(Succeed())
	})

	It("should allow existing pods on different nodes to communicate", func() {
		var httpdIP, httpdNode, ubuntuNode string
		By("checking to create new pods")
		kubectlSafe(nil, "apply", "-f", "manifests/httpd.yaml")
		kubectlSafe(nil, "apply", "-f", "manifests/ubuntu.yaml")
		Eventually(func() error {
			pods := &corev1.PodList{}
			err := getResource("default", "pods", "", "", pods)
			if err != nil {
				return err
			}

		OUTER:
			for _, pod := range pods.Items {
				if pod.Name == "httpd" {
					httpdIP = pod.Status.PodIP
					httpdNode = pod.Spec.NodeName
				} else {
					ubuntuNode = pod.Spec.NodeName
				}
				for _, cond := range pod.Status.Conditions {
					if cond.Type != corev1.PodReady {
						continue
					}
					if cond.Status != corev1.ConditionTrue {
						return fmt.Errorf("pod is not ready: %s", pod.Name)
					}
					continue OUTER
				}
				return fmt.Errorf("pod is not ready: %s", pod.Name)
			}

			return nil
		}).Should(Succeed())

		By("checking communication between pods on different nodes")
		testURL := fmt.Sprintf("http://%s:8000", httpdIP)
		Expect(ubuntuNode).NotTo(Equal(httpdNode))
		out := kubectlSafe(nil, "exec", "ubuntu", "--", "curl", "-s", testURL)
		Expect(string(out)).To(Equal("Hello"))
	})

	It("should delete pods", func() {
		By("deleting dummy pod")
		kubectlSafe(nil, "delete", "pod", "dummy")

		By("checking deleted")
		Eventually(func() error {
			pod := corev1.Pod{}
			err := getResource("default", "pods", "", "", pod)
			if err != nil {
				return nil
			}
			return fmt.Errorf("pod still exists")
		}).Should(Succeed())
	})

	It("should allow to use egress NAT", func() {

		By("running HTTP server on coil-control-plane")
		go runOnNode("coil-control-plane", "/usr/local/bin/echotest")
		time.Sleep(100 * time.Millisecond)

		fakeURL := "http://9.9.9.9"

		By("sending and receiving HTTP request from nat-client")
		data := make([]byte, 1<<20) // 1 MiB
		resp := kubectlSafe(data, "exec", "-i", "nat-client", "--", "curl", "-sf", "-T", "-", fakeURL)
		Expect(resp).To(HaveLen(1 << 20))

		By("running the same test 100 times")
		for i := 0; i < 100; i++ {
			time.Sleep(1 * time.Millisecond)
			resp := kubectlSafe(data, "exec", "-i", "nat-client", "--", "curl", "-sf", "-T", "-", fakeURL)
			Expect(resp).To(HaveLen(1 << 20))
		}

		By("sending and receiving HTTP request from nat-client-sport-auto")
		data = make([]byte, 1<<20) // 1 MiB
		resp = kubectlSafe(data, "exec", "-i", "nat-client-sport-auto", "--", "curl", "-sf", "-T", "-", fakeURL)
		Expect(resp).To(HaveLen(1 << 20))

		By("running the same test 100 times with nat-client-sport-auto")
		for i := 0; i < 100; i++ {
			time.Sleep(1 * time.Millisecond)
			resp := kubectlSafe(data, "exec", "-i", "nat-client-sport-auto", "--", "curl", "-sf", "-T", "-", fakeURL)
			Expect(resp).To(HaveLen(1 << 20))
		}
	})

	It("should create the new pool", func() {
		By("creating new AddressPool")
		kubectlSafe(nil, "apply", "-f", "manifests/dummy_pool.yaml")

		By("checking created")
		Eventually(func() error {
			ap := &coilv2.AddressPool{}
			return getResource("", "addresspool", "dummy", "", ap)
		}).Should(Succeed())
	})

	It("should create new pool and pod", func() {
		By("creating new pod")
		kubectlSafe(nil, "apply", "-f", "manifests/dummy_pod.yaml")

		Eventually(func() error {
			pod := &corev1.Pod{}
			if err := getResource("dummy-ns", "pod", "dummy", "", pod); err != nil {
				return err
			}
			for _, cond := range pod.Status.Conditions {
				if cond.Type == corev1.PodReady {
					return nil
				}
			}
			return nil
		}).Should(Succeed())

		By("running HTTP server on coil-control-plane")
		go runOnNode("coil-control-plane", "/usr/local/bin/echotest")
		time.Sleep(100 * time.Millisecond)

		By("checking that dummy_pod cannot connect to external")
		fakeURL := "http://9.9.9.9"
		out, err := kubectl(nil, "-n", "dummy-ns", "exec", "-i", "dummy_pod", "--", "curl", "-m", "1s", fakeURL)
		Expect(err).To(HaveOccurred())
		Expect(string(out)).To(Equal(""))
	})

	It("should configure egress NAT configurations", func() {
		By("updating new pod")
		kubectlSafe(nil, "apply", "-f", "manifests/dummy_pod_updated.yaml")

		Eventually(func() error {
			pod := &corev1.Pod{}
			if err := getResource("dummy-ns", "pod", "dummy", "", pod); err != nil {
				return err
			}
			for _, cond := range pod.Status.Conditions {
				if cond.Type == corev1.PodReady {
					return nil
				}
			}
			return nil
		}).Should(Succeed())

		By("running HTTP server on coil-control-plane")
		go runOnNode("coil-control-plane", "/usr/local/bin/echotest")
		time.Sleep(10 * time.Second)

		By("checking that dummy_pod can connect to external")
		fakeURL := "http://9.9.9.9"
		data := make([]byte, 1<<20) // 1 MiB
		resp, err := kubectl(data, "exec", "-n", "dummy-ns", "-i", "dummy", "--", "curl", "-sf", "-T", "-", fakeURL)
		Expect(err).NotTo(HaveOccurred())
		Expect(resp).To(HaveLen(1 << 20))

	})
})
