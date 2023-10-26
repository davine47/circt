// RUN: circt-opt %s --esi-connect-services --esi-appid-hier=top=top --esi-build-manifest="top=top to-file=%t1.json" | FileCheck --check-prefix=HIER %s
// RUN: FileCheck --input-file=%t1.json %s

hw.type_scope @__hw_typedecls {
  hw.typedecl @foo, "Foo" : i1
}
!alias = !hw.typealias<@__hw_typedecls::@foo, i1>

!sendI8 = !esi.bundle<[!esi.channel<i8> to "send"]>
!recvI8 = !esi.bundle<[!esi.channel<i8> to "recv"]>

esi.service.decl @HostComms {
  esi.service.to_server @Send : !sendI8
  esi.service.to_client @Recv : !recvI8
}

hw.module @Loopback (in %clk: !seq.clock) {
  %dataInBundle = esi.service.req.to_client <@HostComms::@Recv> (#esi.appid<"loopback_tohw">) {esi.appid=#esi.appid<"loopback_tohw">} : !recvI8
  %dataOut = esi.bundle.unpack from %dataInBundle : !recvI8
  %dataOutBundle = esi.bundle.pack %dataOut : !sendI8
  esi.service.req.to_server %dataOutBundle -> <@HostComms::@Send> (#esi.appid<"loopback_fromhw">) : !sendI8
}

hw.module @top(in %clk: !seq.clock, in %rst: i1) {
  esi.service.instance #esi.appid<"cosim"> svc @HostComms impl as "cosim" (%clk, %rst) : (!seq.clock, i1) -> ()
  hw.instance "m1" @Loopback (clk: %clk: !seq.clock) -> () {esi.appid=#esi.appid<"loopback_inst"[0]>}
  hw.instance "m2" @Loopback (clk: %clk: !seq.clock) -> () {esi.appid=#esi.appid<"loopback_inst"[1]>}
}

// HIER-LABEL:  esi.esi.manifest.hier_root @top {
// HIER:          esi.esi.manifest.service_impl #esi.appid<"cosim"> svc @HostComms by "cosim" with {} {
// HIER:            esi.esi.manifest.impl_conn [#esi.appid<"loopback_inst"[0]>, #esi.appid<"loopback_tohw">] req <@HostComms::@Recv>(!esi.bundle<[!esi.channel<i8> to "recv"]>) with {channel_assignments = {recv = "loopback_inst[0].loopback_tohw.recv"}}
// HIER:            esi.esi.manifest.impl_conn [#esi.appid<"loopback_inst"[0]>, #esi.appid<"loopback_fromhw">] req <@HostComms::@Send>(!esi.bundle<[!esi.channel<i8> from "send"]>) with {channel_assignments = {send = "loopback_inst[0].loopback_fromhw.send"}}
// HIER:            esi.esi.manifest.impl_conn [#esi.appid<"loopback_inst"[1]>, #esi.appid<"loopback_tohw">] req <@HostComms::@Recv>(!esi.bundle<[!esi.channel<i8> to "recv"]>) with {channel_assignments = {recv = "loopback_inst[1].loopback_tohw.recv"}}
// HIER:            esi.esi.manifest.impl_conn [#esi.appid<"loopback_inst"[1]>, #esi.appid<"loopback_fromhw">] req <@HostComms::@Send>(!esi.bundle<[!esi.channel<i8> from "send"]>) with {channel_assignments = {send = "loopback_inst[1].loopback_fromhw.send"}}
// HIER:          }
// HIER:          esi.esi.manifest.hier_node #esi.appid<"loopback_inst"[0]> mod @Loopback {
// HIER:            esi.esi.manifest.req #esi.appid<"loopback_tohw">, <@HostComms::@Recv>, toClient, !esi.bundle<[!esi.channel<i8> to "recv"]>
// HIER:            esi.esi.manifest.req #esi.appid<"loopback_fromhw">, <@HostComms::@Send>, toServer, !esi.bundle<[!esi.channel<i8> to "send"]>
// HIER:          }
// HIER:          esi.esi.manifest.hier_node #esi.appid<"loopback_inst"[1]> mod @Loopback {
// HIER:            esi.esi.manifest.req #esi.appid<"loopback_tohw">, <@HostComms::@Recv>, toClient, !esi.bundle<[!esi.channel<i8> to "recv"]>
// HIER:            esi.esi.manifest.req #esi.appid<"loopback_fromhw">, <@HostComms::@Send>, toServer, !esi.bundle<[!esi.channel<i8> to "send"]>
// HIER:          }
// HIER:        }

// CHECK:       {
// CHECK-LABEL:   "api_version": 1,
// CHECK-LABEL:   "design": [
// CHECK-NEXT:      {
// CHECK-NEXT:        "inst_of": "@top",
// CHECK-NEXT:        "contents": [
// CHECK-NEXT:          {
// CHECK-NEXT:            "class": "service",
// CHECK-NEXT:            "appID": {
// CHECK-NEXT:              "name": "cosim"
// CHECK-NEXT:            },
// CHECK-NEXT:            "service": "@HostComms",
// CHECK-NEXT:            "serviceImplName": "cosim",
// CHECK-NEXT:            "client_details": [
// CHECK-NEXT:              {
// CHECK-NEXT:                "channel_assignments": {
// CHECK-NEXT:                  "recv": "loopback_inst[0].loopback_tohw.recv"
// CHECK-NEXT:                },
// CHECK-NEXT:                "relAppIDPath": [
// CHECK-NEXT:                  {
// CHECK-NEXT:                    "index": 0,
// CHECK-NEXT:                    "name": "loopback_inst"
// CHECK-NEXT:                  },
// CHECK-NEXT:                  {
// CHECK-NEXT:                    "name": "loopback_tohw"
// CHECK-NEXT:                  }
// CHECK-NEXT:                ],
// CHECK-NEXT:                "servicePort": {
// CHECK-NEXT:                  "inner": "Recv",
// CHECK-NEXT:                  "outer_sym": "HostComms"
// CHECK-NEXT:                }
// CHECK-NEXT:              },
// CHECK-NEXT:              {
// CHECK-NEXT:                "channel_assignments": {
// CHECK-NEXT:                  "send": "loopback_inst[0].loopback_fromhw.send"
// CHECK-NEXT:                },
// CHECK-NEXT:                "relAppIDPath": [
// CHECK-NEXT:                  {
// CHECK-NEXT:                    "index": 0,
// CHECK-NEXT:                    "name": "loopback_inst"
// CHECK-NEXT:                  },
// CHECK-NEXT:                  {
// CHECK-NEXT:                    "name": "loopback_fromhw"
// CHECK-NEXT:                  }
// CHECK-NEXT:                ],
// CHECK-NEXT:                "servicePort": {
// CHECK-NEXT:                  "inner": "Send",
// CHECK-NEXT:                  "outer_sym": "HostComms"
// CHECK-NEXT:                }
// CHECK-NEXT:              },
// CHECK-NEXT:              {
// CHECK-NEXT:                "channel_assignments": {
// CHECK-NEXT:                  "recv": "loopback_inst[1].loopback_tohw.recv"
// CHECK-NEXT:                },
// CHECK-NEXT:                "relAppIDPath": [
// CHECK-NEXT:                  {
// CHECK-NEXT:                    "index": 1,
// CHECK-NEXT:                    "name": "loopback_inst"
// CHECK-NEXT:                  },
// CHECK-NEXT:                  {
// CHECK-NEXT:                    "name": "loopback_tohw"
// CHECK-NEXT:                  }
// CHECK-NEXT:                ],
// CHECK-NEXT:                "servicePort": {
// CHECK-NEXT:                  "inner": "Recv",
// CHECK-NEXT:                  "outer_sym": "HostComms"
// CHECK-NEXT:                }
// CHECK-NEXT:              },
// CHECK-NEXT:              {
// CHECK-NEXT:                "channel_assignments": {
// CHECK-NEXT:                  "send": "loopback_inst[1].loopback_fromhw.send"
// CHECK-NEXT:                },
// CHECK-NEXT:                "relAppIDPath": [
// CHECK-NEXT:                  {
// CHECK-NEXT:                    "index": 1,
// CHECK-NEXT:                    "name": "loopback_inst"
// CHECK-NEXT:                  },
// CHECK-NEXT:                  {
// CHECK-NEXT:                    "name": "loopback_fromhw"
// CHECK-NEXT:                  }
// CHECK-NEXT:                ],
// CHECK-NEXT:                "servicePort": {
// CHECK-NEXT:                  "inner": "Send",
// CHECK-NEXT:                  "outer_sym": "HostComms"
// CHECK-NEXT:                }
// CHECK-NEXT:              }
// CHECK-NEXT:            ]
// CHECK-NEXT:          }
// CHECK-NEXT:        ],
// CHECK-NEXT:        "children": [
// CHECK-NEXT:          {
// CHECK-NEXT:            "appID": {
// CHECK-NEXT:              "index": 0,
// CHECK-NEXT:              "name": "loopback_inst"
// CHECK-NEXT:            },
// CHECK-NEXT:            "inst_of": "@Loopback",
// CHECK-NEXT:            "contents": [
// CHECK-NEXT:              {
// CHECK-NEXT:                "class": "client_port",
// CHECK-NEXT:                "appID": {
// CHECK-NEXT:                  "name": "loopback_tohw"
// CHECK-NEXT:                },
// CHECK-NEXT:                "direction": "toClient",
// CHECK-NEXT:                "bundleType": {
// CHECK-NEXT:                  "circt_name": "!esi.bundle<[!esi.channel<i8> to \"recv\"]>"
// CHECK-NEXT:                }
// CHECK-NEXT:              },
// CHECK-NEXT:              {
// CHECK-NEXT:                "class": "client_port",
// CHECK-NEXT:                "appID": {
// CHECK-NEXT:                  "name": "loopback_fromhw"
// CHECK-NEXT:                },
// CHECK-NEXT:                "direction": "toServer",
// CHECK-NEXT:                "bundleType": {
// CHECK-NEXT:                  "circt_name": "!esi.bundle<[!esi.channel<i8> to \"send\"]>"
// CHECK-NEXT:                }
// CHECK-NEXT:              }
// CHECK-NEXT:            ],
// CHECK-NEXT:            "children": []
// CHECK-NEXT:          },
// CHECK-NEXT:          {
// CHECK-NEXT:            "appID": {
// CHECK-NEXT:              "index": 1,
// CHECK-NEXT:              "name": "loopback_inst"
// CHECK-NEXT:            },
// CHECK-NEXT:            "inst_of": "@Loopback",
// CHECK-NEXT:            "contents": [
// CHECK-NEXT:              {
// CHECK-NEXT:                "class": "client_port",
// CHECK-NEXT:                "appID": {
// CHECK-NEXT:                  "name": "loopback_tohw"
// CHECK-NEXT:                },
// CHECK-NEXT:                "direction": "toClient",
// CHECK-NEXT:                "bundleType": {
// CHECK-NEXT:                  "circt_name": "!esi.bundle<[!esi.channel<i8> to \"recv\"]>"
// CHECK-NEXT:                }
// CHECK-NEXT:              },
// CHECK-NEXT:              {
// CHECK-NEXT:                "class": "client_port",
// CHECK-NEXT:                "appID": {
// CHECK-NEXT:                  "name": "loopback_fromhw"
// CHECK-NEXT:                },
// CHECK-NEXT:                "direction": "toServer",
// CHECK-NEXT:                "bundleType": {
// CHECK-NEXT:                  "circt_name": "!esi.bundle<[!esi.channel<i8> to \"send\"]>"
// CHECK-NEXT:                }
// CHECK-NEXT:              }
// CHECK-NEXT:            ],
// CHECK-NEXT:            "children": []
// CHECK-NEXT:          }
// CHECK-NEXT:        ]
// CHECK-NEXT:      }
// CHECK-NEXT:    ],
// CHECK-LABEL:   "types": [
// CHECK-NEXT:      {
// CHECK-NEXT:        "channels": [
// CHECK-NEXT:          {
// CHECK-NEXT:            "direction": "to",
// CHECK-NEXT:            "name": "recv",
// CHECK-NEXT:            "type": {
// CHECK-NEXT:              "circt_name": "!esi.channel<i8>",
// CHECK-NEXT:              "dialect": "esi",
// CHECK-NEXT:              "hw_bitwidth": 8,
// CHECK-NEXT:              "inner": {
// CHECK-NEXT:                "circt_name": "i8",
// CHECK-NEXT:                "dialect": "builtin",
// CHECK-NEXT:                "hw_bitwidth": 8,
// CHECK-NEXT:                "mnemonic": "int",
// CHECK-NEXT:                "signedness": "signless"
// CHECK-NEXT:              },
// CHECK-NEXT:              "mnemonic": "channel"
// CHECK-NEXT:            }
// CHECK-NEXT:          }
// CHECK-NEXT:        ],
// CHECK-NEXT:        "circt_name": "!esi.bundle<[!esi.channel<i8> to \"recv\"]>",
// CHECK-NEXT:        "dialect": "esi",
// CHECK-NEXT:        "mnemonic": "bundle"
// CHECK-NEXT:      },
// CHECK-NEXT:      {
// CHECK-NEXT:        "channels": [
// CHECK-NEXT:          {
// CHECK-NEXT:            "direction": "to",
// CHECK-NEXT:            "name": "send",
// CHECK-NEXT:            "type": {
// CHECK-NEXT:              "circt_name": "!esi.channel<i8>",
// CHECK-NEXT:              "dialect": "esi",
// CHECK-NEXT:              "hw_bitwidth": 8,
// CHECK-NEXT:              "inner": {
// CHECK-NEXT:                "circt_name": "i8",
// CHECK-NEXT:                "dialect": "builtin",
// CHECK-NEXT:                "hw_bitwidth": 8,
// CHECK-NEXT:                "mnemonic": "int",
// CHECK-NEXT:                "signedness": "signless"
// CHECK-NEXT:              },
// CHECK-NEXT:              "mnemonic": "channel"
// CHECK-NEXT:            }
// CHECK-NEXT:          }
// CHECK-NEXT:        ],
// CHECK-NEXT:        "circt_name": "!esi.bundle<[!esi.channel<i8> to \"send\"]>",
// CHECK-NEXT:        "dialect": "esi",
// CHECK-NEXT:        "mnemonic": "bundle"
// CHECK-NEXT:      }
// CHECK-NEXT:    ]
// CHECK-NEXT:  }