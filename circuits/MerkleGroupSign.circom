pragma circom 2.1.4;

include "circomlib/poseidon.circom";
// include "https://github.com/0xPARC/circom-secp256k1/blob/master/circuits/bigint.circom";

template SecretToPublic () {
    signal input sk;
    signal output pk;
    
    component poseidon = Poseidon(1);

    poseidon.inputs[0] <== sk;
    pk <== poseidon.out;

}

template Sign() {
    signal input m;
    signal input sk; // private
    signal pk;

    component checker = SecretToPublic();
    checker.sk <== sk;
    pk <== checker.pk;

    // log("hash", pk);

    // dummy constraints to avoid leaving unused signals
    signal mSquared;
    mSquared <== m * m ;
}

// template GroupSign(n) {
//     signal input m;
//     signal input sk; // private
//     signal input pk[n];

//     component checker = SecretToPublic();
//     checker.sk <== sk;
//     // pk <== checker.pk;

//     signal zeroChecker[n+1];
//     zeroChecker[0] <== 1;
//     for (var i = 0; i < n; i++) {
//         zeroChecker[i+1] <== zeroChecker[i] * (pk[i] - checker.pk);
//     }

//     zeroChecker[n] === 0;

//     // log("hash", pk);

//     // dummy constraints to avoid leaving unused signals
//     signal mSquared;
//     mSquared <== m * m ;
// }

// if s == 0 returns [in[0], in[1]]
// if s == 1 returns [in[1], in[0]]
template DualMux() {
    signal input in[2];
    signal input index;
    signal output out[2];

    index * (1 - index) === 0;
    out[0] <== (in[1] - in[0])*index + in[0];
    out[1] <== (in[0] - in[1])*index + in[1];
}

template MerkleTreeMembership(nLevels) {
    // signal input sk; /// private
    signal input pathIndices[nLevels];
    signal input siblings[nLevels];
    signal input root;

    component mux[nLevels];
    component poseidons[nLevels];


    // component checker = SecretToPublic();
    // checker.sk <== sk;

    signal input leaf;
    // leaf <== checker.pk; 

    signal intermediateHashes[nLevels+1];
    intermediateHashes[0] <== leaf;

    for (var i = 0; i < nLevels; i++) {
        mux[i] = DualMux();
        mux[i].in[0] <== intermediateHashes[i];
        mux[i].in[1] <== siblings[i];
        mux[i].index <== pathIndices[i];

        poseidons[i] = Poseidon(2);
        poseidons[i].inputs[0] <== mux[i].out[0];
        poseidons[i].inputs[1] <== mux[i].out[1];
        intermediateHashes[i+1] <== poseidons[i].out;
    }

    root === intermediateHashes[nLevels];
}


component main = MerkleTreeMembership(15);

// "19065150524771031435284970883882288895168425523179566388456001105768498065277"

/* INPUT = {
    "root": "12890874683796057475982638126021753466203617277177808903147539631297044918772",
    "leaf": "1355224352695827483975080807178260403365748530407",
    "siblings": [
        "1",
        "217234377348884654691879377518794323857294947151490278790710809376325639809",
        "18624361856574916496058203820366795950790078780687078257641649903530959943449",
        "19831903348221211061287449275113949495274937755341117892716020320428427983768",
        "5101361658164783800162950277964947086522384365207151283079909745362546177817",
        "11552819453851113656956689238827707323483753486799384854128595967739676085386",
        "10483540708739576660440356112223782712680507694971046950485797346645134034053",
        "7389929564247907165221817742923803467566552273918071630442219344496852141897",
        "6373467404037422198696850591961270197948259393735756505350173302460761391561",
        "14340012938942512497418634250250812329499499250184704496617019030530171289909",
        "10566235887680695760439252521824446945750533956882759130656396012316506290852",
        "14058207238811178801861080665931986752520779251556785412233046706263822020051",
        "1841804857146338876502603211473795482567574429038948082406470282797710112230",
        "6068974671277751946941356330314625335924522973707504316217201913831393258319",
        "10344803844228993379415834281058662700959138333457605334309913075063427817480"
    ],
    "pathIndices": [
        "1",
        "1",
        "1",
        "1",
        "1",
        "1",
        "1",
        "1",
        "1",
        "1",
        "1",
        "1",
        "1",
        "1",
        "1"
    ]
} */
