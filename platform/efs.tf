module platform_efs {
    source = "../components/efs"
    fs_unique_name = "platform-efs"
    subnet_ids = module.vpc.subnet_private_with_nat_ids
    vpc_security_group_ids = [module.efs_security_group.security_group_id]
    access_points = merge(
        {
            "src-jenkins" = { root_path = "/share", owner_gid = 0 }
            "chain-bootstrap" = { root_path = "/share", owner_gid = 0 }
        },
    )
}