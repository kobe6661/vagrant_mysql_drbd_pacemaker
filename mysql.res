resource mysql {
  protocol C;
  device    minor 0;
  disk      "/dev/sdb";
  meta-disk internal;
  on grizzly1 {
    address ipv4 10.1.2.44:7700;
  }
  on grizzly2 {
    address ipv4 10.1.2.45:7700;
  }
  syncer {
    rate 1000M;
    verify-alg md5;
  }
  startup {
    wfc-timeout 1;
    degr-wfc-timeout 1;   
  }
  disk {
    fencing resource-only;
  }
  handlers {
    fence-peer "/usr/lib/drbd/crm-fence-peer.sh";
    after-resync-target "/usr/lib/drbd/crm-unfence-peer.sh";
  }
  net {
    data-integrity-alg md5;
  }
}
