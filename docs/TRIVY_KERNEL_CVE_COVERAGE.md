# Kernel CVE coverage — Trivy CRITICAL/HIGH

Generated from `trivy-results.json` of the 12 November 2026 build. Every finding below is in `linux-modules-6.8.0-1069-aws` (`6.8.0-1069.74~22.04.1`), Trivy status `affected`, with no `FixedVersion`. These findings stay open in Trivy until Ubuntu publishes a fixed `linux-aws-6.8` kernel; this table records how exposure is reduced in the meantime.

| Category | CRITICAL | HIGH |
|---|---:|---:|
| Module blocked | 3 | 121 |
| Restricted (sysctl/userns) | 2 | 37 |
| Code not built for x86_64 | 0 | 6 |
| Residual | 0 | 11 |
| **Total** | 5 | 175 |

- **Module blocked:** the vulnerable code is in a loadable module that `/etc/modprobe.d/98-golden-image-kernel-cve-mitigation.conf` prevents from loading.
- **Restricted:** the code is built into the kernel; the build sets sysctls that remove the unprivileged path to it (BPF, perf, user namespaces).
- **Code not built for x86_64:** the fix is in code for another architecture or SoC. Trivy matches the source package, not the compiled kernel.
- **Residual:** built-in or required code with no mitigation that keeps the image usable.

| Severity | CVE | Upstream fix subject | Category | Mitigation |
|---|---|---|---|---|
| CRITICAL | [CVE-2026-90162](https://ubuntu.com/security/CVE-2026-90162) | ksmbd: defer publishing granted locks to prevent UAF/double-free race | Module blocked | ksmbd |
| CRITICAL | [CVE-2026-93221](https://ubuntu.com/security/CVE-2026-93221) | nfsd: convert nfsd_net boolean flags to unsigned long flags word | Module blocked | nfsd |
| CRITICAL | [CVE-2026-68426](https://ubuntu.com/security/CVE-2026-68426) | xfrm: fix stale skb->prev after async crypto steals a GSO segment | Module blocked | esp4, esp6, esp4_offload, esp6_offload, xfrm_user, xfrm_interface, af_key |
| CRITICAL | [CVE-2026-63825](https://ubuntu.com/security/CVE-2026-63825) | gcov: use atomic counter updates to fix concurrent access crashes | Restricted (sysctl/userns) | only reachable if CONFIG_GCOV_KERNEL is enabled; build log records the setting |
| CRITICAL | [CVE-2026-64523](https://ubuntu.com/security/CVE-2026-64523) | net/handshake: Take a long-lived file reference at submit | Restricted (sysctl/userns) | built-in; consumers nfsd and nvmet_tcp blocked |
| HIGH | [CVE-2025-68730](https://ubuntu.com/security/CVE-2025-68730) | accel/ivpu: Fix page fault in ivpu_bo_unbind_all_bos_from_context() | Module blocked | intel_vpu |
| HIGH | [CVE-2026-72375](https://ubuntu.com/security/CVE-2026-72375) | afs: Fix reinitialisation of the inode, in particular ->lock_work | Module blocked | kafs, rxrpc |
| HIGH | [CVE-2026-74506](https://ubuntu.com/security/CVE-2026-74506) | afs: Fix UAF when sending a message | Module blocked | kafs, rxrpc |
| HIGH | [CVE-2026-74388](https://ubuntu.com/security/CVE-2026-74388) | ALSA: seq: oss: Fix UAF at handling events with embedded SysEx data | Module blocked | snd_seq_oss, snd |
| HIGH | [CVE-2026-23208](https://ubuntu.com/security/CVE-2026-23208) | ALSA: usb-audio: Prevent excessive number of frames | Module blocked | snd_usb_audio, snd |
| HIGH | [CVE-2026-68152](https://ubuntu.com/security/CVE-2026-68152) | amt: fix use-after-free in AMT delayed works | Module blocked | amt |
| HIGH | [CVE-2022-50240](https://ubuntu.com/security/CVE-2022-50240) | android: binder: stop saving a pointer to the VMA | Module blocked | binder_linux |
| HIGH | [CVE-2025-40344](https://ubuntu.com/security/CVE-2025-40344) | ASoC: Intel: avs: Disable periods-elapsed work when closing PCM | Module blocked | snd_soc_avs, snd |
| HIGH | [CVE-2024-35948](https://ubuntu.com/security/CVE-2024-35948) | bcachefs: Check for journal entries overruning end of sb clean section | Module blocked | bcachefs |
| HIGH | [CVE-2024-56591](https://ubuntu.com/security/CVE-2024-56591) | Bluetooth: hci_conn: Use disable_delayed_work_sync | Module blocked | bluetooth |
| HIGH | [CVE-2025-68304](https://ubuntu.com/security/CVE-2025-68304) | Bluetooth: hci_core: lookup hci_conn on RX path on protocol side | Module blocked | bluetooth |
| HIGH | [CVE-2026-80692](https://ubuntu.com/security/CVE-2026-80692) | Bluetooth: hci_sync: hold conn in hci_connect_acl/le_sync() callbacks | Module blocked | bluetooth |
| HIGH | [CVE-2026-74530](https://ubuntu.com/security/CVE-2026-74530) | Bluetooth: hci_sync: hold conn in hci_connect_big_sync() callback | Module blocked | bluetooth |
| HIGH | [CVE-2026-80721](https://ubuntu.com/security/CVE-2026-80721) | Bluetooth: ISO: ensure no dangling hcon references in iso_conn | Module blocked | bluetooth |
| HIGH | [CVE-2026-74533](https://ubuntu.com/security/CVE-2026-74533) | Bluetooth: ISO: fix race of kfree vs kref_get_unless_zero | Module blocked | bluetooth |
| HIGH | [CVE-2026-74534](https://ubuntu.com/security/CVE-2026-74534) | Bluetooth: ISO: fix refcounting of iso_conn | Module blocked | bluetooth |
| HIGH | [CVE-2026-74537](https://ubuntu.com/security/CVE-2026-74537) | Bluetooth: ISO: hold sk properly in iso_conn_ready | Module blocked | bluetooth |
| HIGH | [CVE-2026-90256](https://ubuntu.com/security/CVE-2026-90256) | Bluetooth: L2CAP: use proto_lock for l2cap_data to fix l2cap_disconn_ind | Module blocked | bluetooth |
| HIGH | [CVE-2026-74269](https://ubuntu.com/security/CVE-2026-74269) | bnxt: fix head underflow on XDP head-grow | Module blocked | bnxt_en |
| HIGH | [CVE-2026-43034](https://ubuntu.com/security/CVE-2026-43034) | bnxt_en: set backing store type from query type | Module blocked | bnxt_en |
| HIGH | [CVE-2026-80631](https://ubuntu.com/security/CVE-2026-80631) | btrfs: lzo: reject compressed segment that overflows the compressed input | Module blocked | btrfs |
| HIGH | [CVE-2026-74723](https://ubuntu.com/security/CVE-2026-74723) | btrfs: lzo: reject inline extents without valid headers | Module blocked | btrfs |
| HIGH | [CVE-2026-74578](https://ubuntu.com/security/CVE-2026-74578) | crypto: algif_skcipher - force synchronous processing on trees without ctx->state | Module blocked | algif_skcipher |
| HIGH | [CVE-2026-93175](https://ubuntu.com/security/CVE-2026-93175) | drm/amd/display: Fix dangling pointer in CRTC reset function | Module blocked | amdgpu |
| HIGH | [CVE-2026-93176](https://ubuntu.com/security/CVE-2026-93176) | drm/amd/display: Fix dangling pointer in plane reset function | Module blocked | amdgpu |
| HIGH | [CVE-2024-38581](https://ubuntu.com/security/CVE-2024-38581) | drm/amdgpu/mes: fix use-after-free issue | Module blocked | amdgpu |
| HIGH | [CVE-2026-97493](https://ubuntu.com/security/CVE-2026-97493) | drm/amdgpu: Bound GPIO I2C table entry count from VBIOS | Module blocked | amdgpu |
| HIGH | [CVE-2026-63879](https://ubuntu.com/security/CVE-2026-63879) | drm/amdgpu: fix amdgpu_hmm_range_get_pages | Module blocked | amdgpu |
| HIGH | [CVE-2026-68245](https://ubuntu.com/security/CVE-2026-68245) | drm/amdgpu: fix lifetime issue of amdgpu_vm_get_task_info_pasid() | Module blocked | amdgpu |
| HIGH | [CVE-2026-68103](https://ubuntu.com/security/CVE-2026-68103) | drm/amdgpu: reject mapping a reserved doorbell to a new queue | Module blocked | amdgpu |
| HIGH | [CVE-2026-68447](https://ubuntu.com/security/CVE-2026-68447) | drm/amdkfd: clamp v9 CRIU control stack checkpoint copy to BO size | Module blocked | amdgpu |
| HIGH | [CVE-2026-68257](https://ubuntu.com/security/CVE-2026-68257) | drm/amdkfd: fix 32-bit overflow in CWSR total size calculation | Module blocked | amdgpu |
| HIGH | [CVE-2026-89810](https://ubuntu.com/security/CVE-2026-89810) | drm/amdkfd: Fix error path at svm_migrate_copy_to_ram | Module blocked | amdgpu |
| HIGH | [CVE-2025-71315](https://ubuntu.com/security/CVE-2025-71315) | drm/vkms: Convert to DRM's vblank timer | Module blocked | vkms |
| HIGH | [CVE-2025-68251](https://ubuntu.com/security/CVE-2025-68251) | erofs: avoid infinite loops due to corrupted subpage compact indexes | Module blocked | erofs |
| HIGH | [CVE-2026-90161](https://ubuntu.com/security/CVE-2026-90161) | erofs: fix interlaced ztailpacking pclusters | Module blocked | erofs |
| HIGH | [CVE-2026-23239](https://ubuntu.com/security/CVE-2026-23239) | espintcp: Fix race condition in espintcp_close() | Module blocked | esp4, esp6 (espintcp is built into the ESP modules) |
| HIGH | [CVE-2026-63819](https://ubuntu.com/security/CVE-2026-63819) | f2fs: fix to do sanity check on f2fs_get_node_folio_ra() | Module blocked | f2fs |
| HIGH | [CVE-2025-40025](https://ubuntu.com/security/CVE-2025-40025) | f2fs: fix to do sanity check on node footer for non inode dnode | Module blocked | f2fs |
| HIGH | [CVE-2026-23265](https://ubuntu.com/security/CVE-2026-23265) | f2fs: fix to do sanity check on node footer in {read,write}_end_io | Module blocked | f2fs |
| HIGH | [CVE-2025-71074](https://ubuntu.com/security/CVE-2025-71074) | functionfs: fix the open/removal races | Module blocked | usb_f_fs, libcomposite |
| HIGH | [CVE-2026-53024](https://ubuntu.com/security/CVE-2026-53024) | greybus: raw: fix use-after-free if write is called after disconnect | Module blocked | greybus, gb_raw |
| HIGH | [CVE-2026-43048](https://ubuntu.com/security/CVE-2026-43048) | HID: core: Mitigate potential OOB by removing bogus memset() | Module blocked | hid, usbhid, hid_generic (if built-in: residual, no HID devices on EC2) |
| HIGH | [CVE-2026-23377](https://ubuntu.com/security/CVE-2026-23377) | ice: change XDP RxQ frag_size from DMA write length to xdp.frame_sz | Module blocked | ice |
| HIGH | [CVE-2026-80693](https://ubuntu.com/security/CVE-2026-80693) | idpf: bound interrupt-vector register fill to the allocated array | Module blocked | idpf |
| HIGH | [CVE-2026-97603](https://ubuntu.com/security/CVE-2026-97603) | idpf: disable DIM work before freeing q_vectors | Module blocked | idpf |
| HIGH | [CVE-2024-44964](https://ubuntu.com/security/CVE-2024-44964) | idpf: fix memory leaks and crashes while performing a soft reset | Module blocked | idpf |
| HIGH | [CVE-2025-71073](https://ubuntu.com/security/CVE-2025-71073) | Input: lkkbd - disable pending work before freeing device | Module blocked | lkkbd |
| HIGH | [CVE-2026-74317](https://ubuntu.com/security/CVE-2026-74317) | ixgbe: do not configure xps for XDP queues | Module blocked | ixgbe (EC2 uses ena/ixgbevf, which stay allowed) |
| HIGH | [CVE-2025-22043](https://ubuntu.com/security/CVE-2025-22043) | ksmbd: add bounds check for durable handle context | Module blocked | ksmbd |
| HIGH | [CVE-2026-90155](https://ubuntu.com/security/CVE-2026-90155) | ksmbd: detach blocked lock requests before freeing | Module blocked | ksmbd |
| HIGH | [CVE-2026-93282](https://ubuntu.com/security/CVE-2026-93282) | ksmbd: fix maximum allowed access checks | Module blocked | ksmbd |
| HIGH | [CVE-2026-89788](https://ubuntu.com/security/CVE-2026-89788) | ksmbd: fix tree connection use-after-free in smb2_tree_connect() | Module blocked | ksmbd |
| HIGH | [CVE-2025-37776](https://ubuntu.com/security/CVE-2025-37776) | ksmbd: fix use-after-free in smb_break_all_levII_oplock() | Module blocked | ksmbd |
| HIGH | [CVE-2026-43379](https://ubuntu.com/security/CVE-2026-43379) | ksmbd: fix use-after-free in smb_lazy_parent_lease_break_close() | Module blocked | ksmbd |
| HIGH | [CVE-2026-98420](https://ubuntu.com/security/CVE-2026-98420) | ksmbd: follow SMB2 session expiration semantics | Module blocked | ksmbd |
| HIGH | [CVE-2026-98115](https://ubuntu.com/security/CVE-2026-98115) | ksmbd: safely drain sessions during logoff | Module blocked | ksmbd |
| HIGH | [CVE-2026-90167](https://ubuntu.com/security/CVE-2026-90167) | ksmbd: serialize oplock close with pending break ownership | Module blocked | ksmbd |
| HIGH | [CVE-2026-31410](https://ubuntu.com/security/CVE-2026-31410) | ksmbd: use volume UUID in FS_OBJECT_ID_INFORMATION | Module blocked | ksmbd |
| HIGH | [CVE-2025-40274](https://ubuntu.com/security/CVE-2025-40274) | KVM: guest_memfd: Remove bindings on memslot deletion when gmem is dying | Module blocked | kvm, kvm_intel, kvm_amd |
| HIGH | [CVE-2026-68081](https://ubuntu.com/security/CVE-2026-68081) | KVM: nVMX: Put vmcs12 pages if nested VM-Enter fails due to invalid guest state | Module blocked | kvm, kvm_intel, kvm_amd |
| HIGH | [CVE-2026-98863](https://ubuntu.com/security/CVE-2026-98863) | KVM: x86: Re-pend GET_NESTED_STATE_PAGES if getting said pages fails | Module blocked | kvm, kvm_intel, kvm_amd |
| HIGH | [CVE-2026-43263](https://ubuntu.com/security/CVE-2026-43263) | media: chips-media: wave5: Fix Null reference while testing fluster | Module blocked | wave5 |
| HIGH | [CVE-2026-97513](https://ubuntu.com/security/CVE-2026-97513) | media: chips-media: wave5: Release m2m_ctx after Instance Removed from List | Module blocked | wave5 |
| HIGH | [CVE-2026-43042](https://ubuntu.com/security/CVE-2026-43042) | mpls: add seqcount to protect the platform_label{,s} pair | Module blocked | mpls_router, mpls_iptunnel, mpls_gso |
| HIGH | [CVE-2026-43464](https://ubuntu.com/security/CVE-2026-43464) | net/mlx5e: RX, Fix XDP multi-buf frag counting for legacy RQ | Module blocked | mlx5_core |
| HIGH | [CVE-2025-38717](https://ubuntu.com/security/CVE-2025-38717) | net: kcm: Fix race condition in kcm_unattach() | Module blocked | kcm |
| HIGH | [CVE-2026-45940](https://ubuntu.com/security/CVE-2026-45940) | net: stmmac: fix oops when split header is enabled | Module blocked | stmmac, stmmac_pci, dwmac_intel |
| HIGH | [CVE-2026-98803](https://ubuntu.com/security/CVE-2026-98803) | net: stmmac: fix rx Scatter-Gather support | Module blocked | stmmac, stmmac_pci, dwmac_intel |
| HIGH | [CVE-2026-80905](https://ubuntu.com/security/CVE-2026-80905) | net: tap: fix wrong transport_header when sending VLAN-tagged frame | Module blocked | tap, macvtap |
| HIGH | [CVE-2026-64077](https://ubuntu.com/security/CVE-2026-64077) | netfilter: ebtables: move to two-stage removal scheme | Module blocked | ebtables, ebtable_filter, ebtable_nat, ebtable_broute |
| HIGH | [CVE-2026-80634](https://ubuntu.com/security/CVE-2026-80634) | netfilter: flowtable: avoid num_encaps underflow on bridge VLAN untag | Module blocked | nf_flow_table, nf_flow_table_inet, nft_flow_offload |
| HIGH | [CVE-2026-89675](https://ubuntu.com/security/CVE-2026-89675) | nfsd: fix UAF in async copy cancel and shutdown | Module blocked | nfsd |
| HIGH | [CVE-2026-90149](https://ubuntu.com/security/CVE-2026-90149) | NFSv4/flexfiles: fix NULL dereference for NFSv4.0 data servers | Module blocked | nfs_layout_flexfiles |
| HIGH | [CVE-2026-72198](https://ubuntu.com/security/CVE-2026-72198) | ntfs: reject non-resident records for resident-only attributes | Module blocked | ntfs, ntfs3 |
| HIGH | [CVE-2026-74385](https://ubuntu.com/security/CVE-2026-74385) | nvmet-tcp: check return value of nvmet_tcp_set_queue_sock | Module blocked | nvmet_tcp, nvmet |
| HIGH | [CVE-2026-72162](https://ubuntu.com/security/CVE-2026-72162) | ocfs2: fix UBSAN array-index-out-of-bounds in ocfs2_sum_rightmost_rec | Module blocked | ocfs2 |
| HIGH | [CVE-2026-90204](https://ubuntu.com/security/CVE-2026-90204) | ocfs2: validate DIO orphan slot during inode read | Module blocked | ocfs2 |
| HIGH | [CVE-2026-90320](https://ubuntu.com/security/CVE-2026-90320) | ocfs2: validate external xattr entries when reading metadata | Module blocked | ocfs2 |
| HIGH | [CVE-2026-90321](https://ubuntu.com/security/CVE-2026-90321) | ocfs2: validate inline xattrs during inode block validation | Module blocked | ocfs2 |
| HIGH | [CVE-2026-90205](https://ubuntu.com/security/CVE-2026-90205) | ocfs2: validate orphan slot during inode read | Module blocked | ocfs2 |
| HIGH | [CVE-2026-90417](https://ubuntu.com/security/CVE-2026-90417) | RDMA/cxgb4: Fix dereg_skb leak and double free in write_tpt_entry() | Module blocked | iw_cxgb4 |
| HIGH | [CVE-2026-93154](https://ubuntu.com/security/CVE-2026-93154) | RDMA/irdma: Add refcounting to user ring MRs | Module blocked | irdma |
| HIGH | [CVE-2026-72494](https://ubuntu.com/security/CVE-2026-72494) | RDMA/irdma: Replace waitqueue and flag with completion | Module blocked | irdma |
| HIGH | [CVE-2026-46181](https://ubuntu.com/security/CVE-2026-46181) | RDMA/mlx4: Fix mis-use of RCU in mlx4_srq_event() | Module blocked | mlx4_ib, mlx4_core |
| HIGH | [CVE-2024-57857](https://ubuntu.com/security/CVE-2024-57857) | RDMA/siw: Remove direct link to net_device | Module blocked | siw |
| HIGH | [CVE-2026-46330](https://ubuntu.com/security/CVE-2026-46330) | Revert "net/smc: Introduce TCP ULP support" | Module blocked | smc |
| HIGH | [CVE-2025-68745](https://ubuntu.com/security/CVE-2025-68745) | scsi: qla2xxx: Clear cmds after chip reset | Module blocked | qla2xxx, tcm_qla2xxx |
| HIGH | [CVE-2026-72383](https://ubuntu.com/security/CVE-2026-72383) | sctp: fix addr_wq_timer race in sctp_free_addr_wq() | Module blocked | sctp |
| HIGH | [CVE-2026-74752](https://ubuntu.com/security/CVE-2026-74752) | sctp: validate cookie AUTH state before use | Module blocked | sctp |
| HIGH | [CVE-2026-98439](https://ubuntu.com/security/CVE-2026-98439) | smb/server: cancel async requests when closing connection | Module blocked | ksmbd |
| HIGH | [CVE-2024-46742](https://ubuntu.com/security/CVE-2024-46742) | smb/server: fix potential null-ptr-deref of lease_ctx_info in smb2_open() | Module blocked | ksmbd |
| HIGH | [CVE-2026-89637](https://ubuntu.com/security/CVE-2026-89637) | smb: client: fix UAF and buffer leak in cifs_check_trans2() for malformed secondary T2 | Module blocked | cifs |
| HIGH | [CVE-2025-39933](https://ubuntu.com/security/CVE-2025-39933) | smb: client: let recv_done verify data_offset, data_length and remaining_data_length | Module blocked | cifs |
| HIGH | [CVE-2026-89631](https://ubuntu.com/security/CVE-2026-89631) | smb: client: reject a tree connect response whose byte count is too small | Module blocked | cifs |
| HIGH | [CVE-2026-97565](https://ubuntu.com/security/CVE-2026-97565) | smb: client: reject short READ responses in CIFSSMBRead() | Module blocked | cifs |
| HIGH | [CVE-2026-31536](https://ubuntu.com/security/CVE-2026-31536) | smb: server: let send_done handle a completion without IB_SEND_SIGNALED | Module blocked | ksmbd |
| HIGH | [CVE-2026-53178](https://ubuntu.com/security/CVE-2026-53178) | staging: rtl8723bs: rtw_mlme: add bounds checks before ie_length subtraction | Module blocked | r8723bs |
| HIGH | [CVE-2026-89537](https://ubuntu.com/security/CVE-2026-89537) | SUNRPC: Reject short RFC 4121 MIC tokens in gss_krb5_verify_mic_v2 | Module blocked | rpcsec_gss_krb5 |
| HIGH | [CVE-2026-89528](https://ubuntu.com/security/CVE-2026-89528) | svcrdma: Reject Read lists that exceed the page budget | Module blocked | rpcrdma |
| HIGH | [CVE-2026-68323](https://ubuntu.com/security/CVE-2026-68323) | tipc: serialize udp bearer replicast list updates | Module blocked | tipc |
| HIGH | [CVE-2026-23240](https://ubuntu.com/security/CVE-2026-23240) | tls: Fix race condition in tls_sw_cancel_work_tx() | Module blocked | tls |
| HIGH | [CVE-2026-90324](https://ubuntu.com/security/CVE-2026-90324) | ublk: check import_ubuf() return value | Module blocked | ublk_drv |
| HIGH | [CVE-2025-37906](https://ubuntu.com/security/CVE-2025-37906) | ublk: fix race between io_uring_cmd_complete_in_task and ublk_cancel_cmd | Module blocked | ublk_drv |
| HIGH | [CVE-2026-97988](https://ubuntu.com/security/CVE-2026-97988) | vhost: invalidate vring access on IOTLB transitions | Module blocked | vhost, vhost_net, vhost_vsock, vhost_vdpa |
| HIGH | [CVE-2025-37743](https://ubuntu.com/security/CVE-2025-37743) | wifi: ath12k: Avoid memory leak while enabling statistics | Module blocked | cfg80211, mac80211 (+ ath12k, mt76, rtw89) |
| HIGH | [CVE-2025-68729](https://ubuntu.com/security/CVE-2025-68729) | wifi: ath12k: Fix MSDU buffer types handling in RX error path | Module blocked | cfg80211, mac80211 (+ ath12k, mt76, rtw89) |
| HIGH | [CVE-2026-98341](https://ubuntu.com/security/CVE-2026-98341) | wifi: cfg80211: don't free driver-owned scan requests | Module blocked | cfg80211, mac80211 (+ ath12k, mt76, rtw89) |
| HIGH | [CVE-2026-90343](https://ubuntu.com/security/CVE-2026-90343) | wifi: cfg80211: stop PMSR before P2P and NAN teardown | Module blocked | cfg80211, mac80211 (+ ath12k, mt76, rtw89) |
| HIGH | [CVE-2026-68404](https://ubuntu.com/security/CVE-2026-68404) | wifi: cfg80211: use wiphy work for socket owner autodisconnect | Module blocked | cfg80211, mac80211 (+ ath12k, mt76, rtw89) |
| HIGH | [CVE-2026-68471](https://ubuntu.com/security/CVE-2026-68471) | wifi: ieee80211: validate MLE common info length | Module blocked | cfg80211, mac80211 (+ ath12k, mt76, rtw89) |
| HIGH | [CVE-2026-68409](https://ubuntu.com/security/CVE-2026-68409) | wifi: mac80211: defer link RX stats percpu free to RCU | Module blocked | cfg80211, mac80211 (+ ath12k, mt76, rtw89) |
| HIGH | [CVE-2026-98829](https://ubuntu.com/security/CVE-2026-98829) | wifi: mac80211: drop oversized fragments to avoid extra_len overflow | Module blocked | cfg80211, mac80211 (+ ath12k, mt76, rtw89) |
| HIGH | [CVE-2026-98332](https://ubuntu.com/security/CVE-2026-98332) | wifi: mac80211: only operate on TDLS peers in the TDLS code | Module blocked | cfg80211, mac80211 (+ ath12k, mt76, rtw89) |
| HIGH | [CVE-2026-98333](https://ubuntu.com/security/CVE-2026-98333) | wifi: mac80211: reset the LED state when ifup fails | Module blocked | cfg80211, mac80211 (+ ath12k, mt76, rtw89) |
| HIGH | [CVE-2026-68470](https://ubuntu.com/security/CVE-2026-68470) | wifi: mac80211: validate extension-frame layout before RX | Module blocked | cfg80211, mac80211 (+ ath12k, mt76, rtw89) |
| HIGH | [CVE-2026-98824](https://ubuntu.com/security/CVE-2026-98824) | wifi: mac80211: validate TX status rate metadata | Module blocked | cfg80211, mac80211 (+ ath12k, mt76, rtw89) |
| HIGH | [CVE-2026-90380](https://ubuntu.com/security/CVE-2026-90380) | wifi: mt76: mt792x: fix use-after-free in mt76_rx_poll_complete | Module blocked | cfg80211, mac80211 (+ ath12k, mt76, rtw89) |
| HIGH | [CVE-2025-68360](https://ubuntu.com/security/CVE-2025-68360) | wifi: mt76: wed: use proper wed reference in mt76 wed driver callabacks | Module blocked | cfg80211, mac80211 (+ ath12k, mt76, rtw89) |
| HIGH | [CVE-2026-43213](https://ubuntu.com/security/CVE-2026-43213) | wifi: rtw89: pci: validate sequence number of TX release report | Module blocked | cfg80211, mac80211 (+ ath12k, mt76, rtw89) |
| HIGH | [CVE-2026-72380](https://ubuntu.com/security/CVE-2026-72380) | xen/pvcalls: bound backend response req_id before indexing rsp[] | Module blocked | pvcalls_front |
| HIGH | [CVE-2026-64052](https://ubuntu.com/security/CVE-2026-64052) | block: bio-integrity: Fix null-ptr-deref in bio_integrity_map_user() | Restricted (sysctl/userns) | built-in; user-mapped integrity I/O needs raw block-device access (root/disk group) |
| HIGH | [CVE-2026-98085](https://ubuntu.com/security/CVE-2026-98085) | bpf: backtrack_insn(): Handle ld_{abs,ind} subprog exit edge | Restricted (sysctl/userns) | built-in; kernel.unprivileged_bpf_disabled=1 + net.core.bpf_jit_harden=2 (root/CAP_BPF only) |
| HIGH | [CVE-2026-98084](https://ubuntu.com/security/CVE-2026-98084) | bpf: backtracking shouldn't clear outer frame R1-R5 for callbacks | Restricted (sysctl/userns) | built-in; kernel.unprivileged_bpf_disabled=1 + net.core.bpf_jit_harden=2 (root/CAP_BPF only) |
| HIGH | [CVE-2026-74314](https://ubuntu.com/security/CVE-2026-74314) | bpf: Cancel special fields on map value recycle | Restricted (sysctl/userns) | built-in; kernel.unprivileged_bpf_disabled=1 + net.core.bpf_jit_harden=2 (root/CAP_BPF only) |
| HIGH | [CVE-2024-58100](https://ubuntu.com/security/CVE-2024-58100) | bpf: check changes_pkt_data property for extension programs | Restricted (sysctl/userns) | built-in; kernel.unprivileged_bpf_disabled=1 + net.core.bpf_jit_harden=2 (root/CAP_BPF only) |
| HIGH | [CVE-2026-98134](https://ubuntu.com/security/CVE-2026-98134) | bpf: check_cond_jmp_op(): properly infer if register is null | Restricted (sysctl/userns) | built-in; kernel.unprivileged_bpf_disabled=1 + net.core.bpf_jit_harden=2 (root/CAP_BPF only) |
| HIGH | [CVE-2026-74344](https://ubuntu.com/security/CVE-2026-74344) | bpf: Clear rb node linkage when freeing bpf_rb_root | Restricted (sysctl/userns) | built-in; kernel.unprivileged_bpf_disabled=1 + net.core.bpf_jit_harden=2 (root/CAP_BPF only) |
| HIGH | [CVE-2026-90217](https://ubuntu.com/security/CVE-2026-90217) | bpf: Compare iterator types during state pruning | Restricted (sysctl/userns) | built-in; kernel.unprivileged_bpf_disabled=1 + net.core.bpf_jit_harden=2 (root/CAP_BPF only) |
| HIGH | [CVE-2026-43009](https://ubuntu.com/security/CVE-2026-43009) | bpf: Fix incorrect pruning due to atomic fetch precision tracking | Restricted (sysctl/userns) | built-in; kernel.unprivileged_bpf_disabled=1 + net.core.bpf_jit_harden=2 (root/CAP_BPF only) |
| HIGH | [CVE-2026-74715](https://ubuntu.com/security/CVE-2026-74715) | bpf: Fix netns reference imbalance in conntrack kfuncs | Restricted (sysctl/userns) | built-in; kernel.unprivileged_bpf_disabled=1 + net.core.bpf_jit_harden=2 (root/CAP_BPF only) |
| HIGH | [CVE-2026-72423](https://ubuntu.com/security/CVE-2026-72423) | bpf: Guard conntrack opts error writes | Restricted (sysctl/userns) | built-in; kernel.unprivileged_bpf_disabled=1 + net.core.bpf_jit_harden=2 (root/CAP_BPF only) |
| HIGH | [CVE-2026-98813](https://ubuntu.com/security/CVE-2026-98813) | bpf: Hold map BTF for the memory allocator destructor record | Restricted (sysctl/userns) | built-in; kernel.unprivileged_bpf_disabled=1 + net.core.bpf_jit_harden=2 (root/CAP_BPF only) |
| HIGH | [CVE-2026-90317](https://ubuntu.com/security/CVE-2026-90317) | bpf: Invalidate RCU pointers after final spin unlock | Restricted (sysctl/userns) | built-in; kernel.unprivileged_bpf_disabled=1 + net.core.bpf_jit_harden=2 (root/CAP_BPF only) |
| HIGH | [CVE-2026-98019](https://ubuntu.com/security/CVE-2026-98019) | bpf: mark a NULL call argument precise | Restricted (sysctl/userns) | built-in; kernel.unprivileged_bpf_disabled=1 + net.core.bpf_jit_harden=2 (root/CAP_BPF only) |
| HIGH | [CVE-2026-100074](https://ubuntu.com/security/CVE-2026-100074) | bpf: Mark bpf_refcount field as unique | Restricted (sysctl/userns) | built-in; kernel.unprivileged_bpf_disabled=1 + net.core.bpf_jit_harden=2 (root/CAP_BPF only) |
| HIGH | [CVE-2026-98034](https://ubuntu.com/security/CVE-2026-98034) | bpf: Mark NULL kptr stores precise | Restricted (sysctl/userns) | built-in; kernel.unprivileged_bpf_disabled=1 + net.core.bpf_jit_harden=2 (root/CAP_BPF only) |
| HIGH | [CVE-2026-98033](https://ubuntu.com/security/CVE-2026-98033) | bpf: Preserve inner map identity in callback frames | Restricted (sysctl/userns) | built-in; kernel.unprivileged_bpf_disabled=1 + net.core.bpf_jit_harden=2 (root/CAP_BPF only) |
| HIGH | [CVE-2026-93148](https://ubuntu.com/security/CVE-2026-93148) | bpf: Reject MEM_ALLOC BTF accesses past object bounds | Restricted (sysctl/userns) | built-in; kernel.unprivileged_bpf_disabled=1 + net.core.bpf_jit_harden=2 (root/CAP_BPF only) |
| HIGH | [CVE-2026-98599](https://ubuntu.com/security/CVE-2026-98599) | bpf: Reject non-negative offsets in stack_slot_obj_get_spi() | Restricted (sysctl/userns) | built-in; kernel.unprivileged_bpf_disabled=1 + net.core.bpf_jit_harden=2 (root/CAP_BPF only) |
| HIGH | [CVE-2026-98589](https://ubuntu.com/security/CVE-2026-98589) | bpf: Reject pkt arguments in mutating subprogs | Restricted (sysctl/userns) | built-in; kernel.unprivileged_bpf_disabled=1 + net.core.bpf_jit_harden=2 (root/CAP_BPF only) |
| HIGH | [CVE-2026-93125](https://ubuntu.com/security/CVE-2026-93125) | bpf: Reject rdonly/rdwr_buf_size kfunc arguments that exceed u32 max | Restricted (sysctl/userns) | built-in; kernel.unprivileged_bpf_disabled=1 + net.core.bpf_jit_harden=2 (root/CAP_BPF only) |
| HIGH | [CVE-2026-93144](https://ubuntu.com/security/CVE-2026-93144) | bpf: Reject writes through untrusted BTF pointers | Restricted (sysctl/userns) | built-in; kernel.unprivileged_bpf_disabled=1 + net.core.bpf_jit_harden=2 (root/CAP_BPF only) |
| HIGH | [CVE-2026-98799](https://ubuntu.com/security/CVE-2026-98799) | bpf: Skip detached progs in trampoline images that are still in use | Restricted (sysctl/userns) | built-in; kernel.unprivileged_bpf_disabled=1 + net.core.bpf_jit_harden=2 (root/CAP_BPF only) |
| HIGH | [CVE-2024-58098](https://ubuntu.com/security/CVE-2024-58098) | bpf: track changes_pkt_data property for global functions | Restricted (sysctl/userns) | built-in; kernel.unprivileged_bpf_disabled=1 + net.core.bpf_jit_harden=2 (root/CAP_BPF only) |
| HIGH | [CVE-2026-98800](https://ubuntu.com/security/CVE-2026-98800) | bpf: Wait for an RCU tasks grace period before freeing trampoline progs | Restricted (sysctl/userns) | built-in; kernel.unprivileged_bpf_disabled=1 + net.core.bpf_jit_harden=2 (root/CAP_BPF only) |
| HIGH | [CVE-2026-64036](https://ubuntu.com/security/CVE-2026-64036) | cgroup/rstat: validate cpu before css_rstat_cpu() access | Restricted (sysctl/userns) | built-in; reachable as a BPF kfunc; unprivileged_bpf_disabled=1 |
| HIGH | [CVE-2026-90111](https://ubuntu.com/security/CVE-2026-90111) | ip6mr: do not clone dst in ip6mr_cache_report() | Restricted (sysctl/userns) | built-in IPv6 multicast routing; needs CAP_NET_ADMIN, unprivileged userns disabled |
| HIGH | [CVE-2024-40954](https://ubuntu.com/security/CVE-2024-40954) | net: do not leave a dangling sk pointer, when socket creation fails | Restricted (sysctl/userns) | built-in network core; privileged paths need CAP_NET_ADMIN, unprivileged userns disabled |
| HIGH | [CVE-2026-80725](https://ubuntu.com/security/CVE-2026-80725) | net: gro: properly validate BIG TCP aggregation criteria | Restricted (sysctl/userns) | built-in network core; privileged paths need CAP_NET_ADMIN, unprivileged userns disabled |
| HIGH | [CVE-2026-98570](https://ubuntu.com/security/CVE-2026-98570) | net: ipv6: keep room for the mac header in dst_dev_overhead() | Restricted (sysctl/userns) | built-in network core; privileged paths need CAP_NET_ADMIN, unprivileged userns disabled |
| HIGH | [CVE-2026-72493](https://ubuntu.com/security/CVE-2026-72493) | net: serialize netif_running() check in enqueue_to_backlog() | Restricted (sysctl/userns) | built-in network core; privileged paths need CAP_NET_ADMIN, unprivileged userns disabled |
| HIGH | [CVE-2025-40170](https://ubuntu.com/security/CVE-2025-40170) | net: use dst_dev_rcu() in sk_setup_caps() | Restricted (sysctl/userns) | built-in network core; privileged paths need CAP_NET_ADMIN, unprivileged userns disabled |
| HIGH | [CVE-2026-97960](https://ubuntu.com/security/CVE-2026-97960) | perf/x86/intel: Prevent drain_pebs() reentry | Restricted (sysctl/userns) | built-in; kernel.perf_event_paranoid>=3 (no unprivileged perf) |
| HIGH | [CVE-2026-31692](https://ubuntu.com/security/CVE-2026-31692) | rtnetlink: add missing netlink_ns_capable() check for peer netns | Restricted (sysctl/userns) | built-in network core; privileged paths need CAP_NET_ADMIN, unprivileged userns disabled |
| HIGH | [CVE-2026-74257](https://ubuntu.com/security/CVE-2026-74257) | sockmap: Fix use-after-free in udp_bpf_recvmsg() | Restricted (sysctl/userns) | built-in; sockmap is configured through bpf(); unprivileged_bpf_disabled=1 |
| HIGH | [CVE-2025-40075](https://ubuntu.com/security/CVE-2025-40075) | tcp_metrics: use dst_dev_net_rcu() | Restricted (sysctl/userns) | built-in network core; privileged paths need CAP_NET_ADMIN, unprivileged userns disabled |
| HIGH | [CVE-2026-98364](https://ubuntu.com/security/CVE-2026-98364) | xfrm: hold net_device reference under RCU in bundle creation | Restricted (sysctl/userns) | built-in XFRM core; SAs cannot be configured with xfrm_user/af_key/ESP blocked |
| HIGH | [CVE-2026-53377](https://ubuntu.com/security/CVE-2026-53377) | drm/msm: always recover the gpu | Code not built for x86_64 | Qualcomm MSM GPU driver is not built for x86_64 |
| HIGH | [CVE-2026-53401](https://ubuntu.com/security/CVE-2026-53401) | fbdev: omap2: fix use-after-free in omapfb_mmap | Code not built for x86_64 | OMAP framebuffer is ARM-only |
| HIGH | [CVE-2026-68401](https://ubuntu.com/security/CVE-2026-68401) | firmware: arm_ffa: Fix out-of-bound writes in ffa_setup_and_transmit() | Code not built for x86_64 | Arm FF-A firmware interface is ARM-only |
| HIGH | [CVE-2026-89913](https://ubuntu.com/security/CVE-2026-89913) | KVM: arm64: vgic-v3: take an LPI reference in vgic_v3_save_pending_tables | Code not built for x86_64 | arm64/s390 KVM code is not built for x86_64 |
| HIGH | [CVE-2026-72288](https://ubuntu.com/security/CVE-2026-72288) | KVM: arm64: vgic: Handle race between interrupt affinity change and LPI disabling | Code not built for x86_64 | arm64/s390 KVM code is not built for x86_64 |
| HIGH | [CVE-2026-98652](https://ubuntu.com/security/CVE-2026-98652) | KVM: s390: Add missing srcu in kvm_s390_set_irq_state() | Code not built for x86_64 | arm64/s390 KVM code is not built for x86_64 |
| HIGH | [CVE-2026-23393](https://ubuntu.com/security/CVE-2026-23393) | bridge: cfm: Fix race condition in peer_mep deletion | Residual | bridge module kept (Docker/container networking); needs CAP_NET_ADMIN, unprivileged userns disabled |
| HIGH | [CVE-2025-40190](https://ubuntu.com/security/CVE-2025-40190) | ext4: guard against EA inode refcount underflow in xattr update | Residual | ext4 is the root filesystem; needs a crafted filesystem image mounted by root |
| HIGH | [CVE-2026-92499](https://ubuntu.com/security/CVE-2026-92499) | ext4: validate readdir offset before accessing dirent | Residual | ext4 is the root filesystem; needs a crafted filesystem image mounted by root |
| HIGH | [CVE-2026-52946](https://ubuntu.com/security/CVE-2026-52946) | fs/fcntl: fix SOFTIRQ-unsafe lock order in fasync signaling | Residual | built-in VFS code |
| HIGH | [CVE-2025-71202](https://ubuntu.com/security/CVE-2025-71202) | iommu/sva: invalidate stale IOTLB entries for kernel address space | Residual | built-in IOMMU code; EC2 virtual instances expose no guest IOMMU |
| HIGH | [CVE-2026-53281](https://ubuntu.com/security/CVE-2026-53281) | iommu/vt-d: Avoid NULL pointer dereference or refcount corruption | Residual | built-in IOMMU code; EC2 virtual instances expose no guest IOMMU |
| HIGH | [CVE-2026-90237](https://ubuntu.com/security/CVE-2026-90237) | netfilter: nft_ct: move custom expectation support to helper | Residual | required by the nftables firewall/iptables-nft; needs CAP_NET_ADMIN, unprivileged userns disabled |
| HIGH | [CVE-2026-64078](https://ubuntu.com/security/CVE-2026-64078) | netfilter: x_tables: add and use xtables_unregister_table_exit | Residual | required by the nftables firewall/iptables-nft; needs CAP_NET_ADMIN, unprivileged userns disabled |
| HIGH | [CVE-2026-72472](https://ubuntu.com/security/CVE-2026-72472) | nfs: use nfsi->rwsem to protect traversal of the file lock list | Residual | nfs client; kept for EFS/NFS client mounts |
| HIGH | [CVE-2026-90104](https://ubuntu.com/security/CVE-2026-90104) | NFSv4.1: zero referring call lists before decoding | Residual | nfsv4 client callback code; kept for EFS/NFS client mounts |
| HIGH | [CVE-2026-52991](https://ubuntu.com/security/CVE-2026-52991) | sched/psi: fix race between file release and pressure write | Residual | built-in pressure-stall code |
