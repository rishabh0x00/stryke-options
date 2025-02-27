export const catchAsync = (fn) => (req, res, next) => {
    fn(req, res, next).catch(next);
  };
  
  export const handleBlockchainTransaction = async (tx) => {
    const receipt = await tx.wait();
    if (receipt.status !== 1) {
      throw new Error('Blockchain transaction failed.');
    }
    return receipt;
  };