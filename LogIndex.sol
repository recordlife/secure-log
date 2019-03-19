pragma solidity ^0.4.0;

contract LogIndex {

    uint[] indexArray;
    uint startTimestamp;
    address operator;

    uint32 constant dayTimestamp = 86400000;
    // The time of producing block should be changed according to actual condition.
    uint16 constant amountOfBlocks = 86400 / 5;

    function LogIndex(uint _startTimestamp) public {
        // Beijing time is 8 hours earlier than GMT.
        require((_startTimestamp + 28800000) % dayTimestamp == 0, "The parameter should be the timestamp of 00:00:00.");
        operator = msg.sender;
        startTimestamp = _startTimestamp;
        // create first index
        indexArray.push((block.number << 128) + block.number + amountOfBlocks);
    }

    function addLogPackage(uint64 minTimestamp, uint64 maxTimestamp, uint8 logType, string ipfsAddress) public {
        require(minTimestamp >= startTimestamp, "The minTimestamp should be greater than startTimeStamp.");

        uint minDataIndex = timeStampToDataIndex(minTimestamp);
        uint maxDataIndex = timeStampToDataIndex(maxTimestamp);
        uint currentDataIndex = getCurrentDataIndex();

        // add new index
        if (maxDataIndex > currentDataIndex) {
            for (uint i = 0; i < maxDataIndex - currentDataIndex; i ++) {
                addNewDataIndex();
            }
        }

        // extend the scope of index
        for (uint j = minDataIndex; j <= maxDataIndex; j ++) {
            if (block.number > getMaxBlockNumber(j)) {
                setMaxBlockNumber(j, block.number);
            }
        }
    }

    function getElementByTimestamp(uint timestamp) public view returns (uint, uint) {
        return getElement(timeStampToDataIndex(timestamp));
    }

    function timeStampToDataIndex(uint timestamp) public view returns (uint) {
            uint dataIndex = (timestamp - startTimestamp) / dayTimestamp;
            return dataIndex;
    }

    function getElement(uint dataIndex) public view returns (uint, uint) {
        require(dataIndex < indexArray.length, "This index is out of the bound of array.");

        uint begin = indexArray[dataIndex] >> 128;
        uint end = indexArray[dataIndex] - (begin << 128);

        return (begin, end);
    }

    function getCurrentElement() public view returns (uint, uint) {
        return getElement(indexArray.length - 1);
    }

    function getMinBlockNumber(uint dataIndex) public view returns (uint) {
        require(dataIndex < indexArray.length, "This index is out of the bound of array.");
        return indexArray[dataIndex] >> 128;
    }

    function getMaxBlockNumber(uint dataIndex) public view returns (uint) {
        require(dataIndex < indexArray.length, "This index is out of the bound of array.");
        return indexArray[dataIndex] << 128 >> 128;
    }

    function setMaxBlockNumber(uint dataIndex, uint blockNumber) public {
        require(dataIndex < indexArray.length, "This index is out of the bound of array.");
        uint begin = indexArray[dataIndex] >> 128;
        require(blockNumber > begin, "The maximal block number should be greater than the minimal block number.");
        indexArray[dataIndex] = (begin << 128) + blockNumber;
    }

    function addNewDataIndex() public {
        indexArray.push((block.number << 128) + block.number + amountOfBlocks);
    }

    function getCurrentDataIndex() public view returns (uint) {
        return indexArray.length - 1;
    }
}