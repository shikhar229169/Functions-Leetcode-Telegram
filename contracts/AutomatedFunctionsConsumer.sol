// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {Functions, FunctionsClient} from "./dev/functions/FunctionsClient.sol";
// import "@chainlink/contracts/src/v0.8/dev/functions/FunctionsClient.sol"; // Once published
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

/**
 * @title Automated Functions Consumer contract
 * @notice This contract is a demonstration of using Functions.
 * @notice NOT FOR PRODUCTION USE
 */
contract LeetcodeTelegram is FunctionsClient, ConfirmedOwner, AutomationCompatibleInterface {
  using Functions for Functions.Request;

  bytes public requestCBOR;
  bytes32 public latestRequestId;
  bytes public latestResponse;
  bytes public latestError;
  uint64 public subscriptionId;
  uint32 public fulfillGasLimit;
  uint256 public updateInterval;
  uint256 public lastUpkeepTimeStamp;
  uint256 public upkeepCounter;
  uint256 public responseCounter;
  uint256 public subid;

  event OCRResponse(bytes32 indexed requestId, bytes result, bytes err);

  /**
   * @notice Executes once when a contract is created to initialize state variables
   *
   * @param oracle The FunctionsOracle contract
   * @param _subscriptionId The Functions billing subscription ID used to pay for Functions requests
   * @param _fulfillGasLimit Maximum amount of gas used to call the client contract's `handleOracleFulfillment` function
   * @param _updateInterval Time interval at which Chainlink Automation should call performUpkeep
   */
  constructor(
    address oracle,
    uint64 _subscriptionId,
    uint32 _fulfillGasLimit,
    uint256 _updateInterval,
    uint256 _subid
  ) FunctionsClient(oracle) ConfirmedOwner(msg.sender) {
    updateInterval = _updateInterval;
    subscriptionId = _subscriptionId;
    fulfillGasLimit = _fulfillGasLimit;
    lastUpkeepTimeStamp = block.timestamp;
    subid = _subid;
  }

  function generateRequest(
    string calldata source,
    bytes calldata secrets,
    string[] calldata args
  ) public pure returns (bytes memory) {
    Functions.Request memory req;
    req.initializeRequest(Functions.Location.Inline, Functions.CodeLanguage.JavaScript, source);
    if (secrets.length > 0) {
      req.addRemoteSecrets(secrets);
    }
    if (args.length > 0) req.addArgs(args);

    return req.encodeCBOR();
  }

  function setRequest(
    uint64 _subscriptionId,
    uint32 _fulfillGasLimit,
    uint256 _updateInterval,
    bytes calldata newRequestCBOR
  ) external onlyOwner {
    updateInterval = _updateInterval;
    subscriptionId = _subscriptionId;
    fulfillGasLimit = _fulfillGasLimit;
    requestCBOR = newRequestCBOR;
  }

  function checkUpkeep(bytes memory) public view override returns (bool upkeepNeeded, bytes memory) {
    upkeepNeeded = (block.timestamp - lastUpkeepTimeStamp) > updateInterval;
  }

  function performUpkeep(bytes calldata) external override {
    (bool upkeepNeeded, ) = checkUpkeep("");
    require(upkeepNeeded, "Time interval not met");
    lastUpkeepTimeStamp = block.timestamp;
    upkeepCounter = upkeepCounter + 1;

    bytes32 requestId = s_oracle.sendRequest(subscriptionId, requestCBOR, fulfillGasLimit);

    s_pendingRequests[requestId] = s_oracle.getRegistry();
    emit RequestSent(requestId);
    latestRequestId = requestId;
  }

  function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
    latestResponse = response;
    latestError = err;
    responseCounter = responseCounter + 1;
    emit OCRResponse(requestId, response, err);
  }

  function updateOracleAddress(address oracle) public onlyOwner {
    setOracle(oracle);
  }
}
