/**
 * Created by masatomix on 2017/04/24.
 * Masatomi KINO <kino@primebrains.co.jp>
 */

"use strict";

const AWS = require('aws-sdk');
const me = this;

// paramsに一致するinstancesを検索。
// params = {InstanceIds:["id1","id2"]}
// promiseを返す。
module.exports.searchInstances = (options, params) => {
  const promise = new Promise((resolve, reject) => {
    const ec2 = new AWS.EC2(options);
    ec2.describeInstances(params, (err, data) => {
      const instances = [];
      if (err) {
        reject(err);
        return;
      } else {
        const reservations = data.Reservations;
        for (let index = 0; index < reservations.length; index++) {
          for (let j = 0; j < reservations[index].Instances.length; j++) {
            instances.push(reservations[index].Instances[j]);
          }
        }
      }
      resolve(instances);
    });
  });
  return promise;
};


module.exports.internalStartInstances = (options, instances) => {
  return new Promise((resolve, reject) => {
    const datas = [];

    const promises = [];
    // for文で、起動処理。
    for (let index = 0; index < instances.length; index++) {
      const instanceId = instances[index].InstanceId;
      const ec2 = new AWS.EC2(options);

      const p = new Promise((resolve1, reject1) => {
        // {InstanceIds: [instanceId]}
        ec2.startInstances({InstanceIds: [instanceId]}, (err, data) => {
          if (err) {
            reject1(err);
          } else {
            datas.push(data);
            console.log(instanceId + " の起動が開始されました");
            resolve1(data);
          }
        });
      });
      promises.push(p);
    }

    const onSuccessed = () => {
      resolve(datas);
    };
    const onRejected = (error) => {
      reject(error);
    };

    Promise.all(promises).then(onSuccessed, onRejected);
  });
};

module.exports.internalStopInstances = (options, instances) => {
  return new Promise((resolve, reject) => {
    const datas = [];

    const promises = [];
    // for文で、起動処理。
    for (let index = 0; index < instances.length; index++) {
      const instanceId = instances[index].InstanceId;
      const ec2 = new AWS.EC2(options);

      const p = new Promise((resolve1, reject1) => {
        // {InstanceIds: [instanceId]}
        ec2.stopInstances({InstanceIds: [instanceId]}, (err, data) => {
          if (err) {
            reject1(err);
          } else {
            datas.push(data);
            console.log(instanceId + " の停止が開始されました");
            resolve1(data);
          }
        });
      });
      promises.push(p);
    }

    const onSuccessed = () => {
      resolve(datas);
    };
    const onRejected = (error) => {
      reject(error);
    };

    Promise.all(promises).then(onSuccessed, onRejected);
  });
};


module.exports.doInstances = (options, params, start_or_end) => {
  const onRejected = (error) => {
  };
  const promise = me.searchInstances(options, params);
  promise.then(function (instances) {
    return start_or_end(options, instances);
  }, onRejected);
  return promise;
}


// paramsに一致するinstancesを起動させる。。
// params = {InstanceIds:["id1","id2"]}
// Promiseを返す
module.exports.startInstances = (options, params) => {
  return me.doInstances(options, params, me.internalStartInstances);
};


module.exports.stopInstances = (options, params) => {
  return me.doInstances(options, params, me.internalStopInstances);
};


module.exports.onRejected = (error) => {
  console.log(error.message);
};


// const ids = {InstanceIds: ["xx", "yy"]};
// me.startInstances({region: 'ap-northeast-1'}, ids)
//   .then((datas) => {
//     for (let data of datas) {
//       console.log("-------------------------------");
//       console.log(data);
//       console.log("-------------------------------");
//     }
//   }, me.onRejected);
//
// me.stopInstances({region: 'ap-northeast-1'}, ids)
//   .then((datas) => {
//     for (let data of datas) {
//       console.log("-------------------------------");
//       console.log(data);
//       console.log("-------------------------------");
//     }
//   }, me.onRejected);


// // AWSのCredentialsファイルから情報取得
// const credentials = new AWS.SharedIniFileCredentials({profile: 'default'});
// AWS.config.credentials = credentials;
// const ec2 = new AWS.EC2({region: 'ap-northeast-1'});
//
// ec2.describeInstances((err, data) => {
//   if (err) {
//     console.log(err, err.stack);
//   } else {
//     for (var index = 0; index < data.Reservations.length; index++) {
//       data.Reservations[index].Instances.forEach(
//         function (instance) {
//           console.log("PublicDnsName: " + instance.PublicDnsName);
//           console.log("PublicIpAddress: " + instance.PublicIpAddress);
//           console.log("State: " + JSON.stringify(instance.State));
//         }
//       );
//     }
//   }
// });


// const utils = require('./utils.js')
// utils.describeInstances (
//   {
//     accessKeyId: 'xxx',
//     secretAccessKey: 'xxx',
//     region: 'ap-northeast-1'
//   },
//   function(instance){
//     console.log("PublicDnsName: " + instance.PublicDnsName);
//     console.log("State: " + JSON.stringify(instance.State));
//     console.log("PublicIpAddress: " + instance.PublicIpAddress);
//     console.log("PrivateIpAddress: " + instance.PrivateIpAddress);
//     console.log("PrivateDnsName: " + instance.PrivateDnsName);
//   }
// );


