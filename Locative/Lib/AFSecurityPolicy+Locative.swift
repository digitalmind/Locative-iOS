import AFNetworking

extension AFSecurityPolicy {
    static var locativePolicy: AFSecurityPolicy {
        get {
            let policy = AFSecurityPolicy(pinningMode: .none)
            policy.allowInvalidCertificates = true
            policy.validatesDomainName = false
            return policy
        }
    }
}
