// Copyright 2022 The Casdoor Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import React, {useEffect} from "react";
import i18next from "i18next";

export const RedirectForm = (props) => {

  useEffect(() => {
    document.getElementById("saml").submit();
  }, []);

  return (
    <React.Fragment>
      <p>{i18next.t("login:Redirecting, please wait.")}</p>
      <form id="saml" method="post" action={props.redirectUrl}>
        <input
          type="hidden"
          name="SAMLResponse"
          id="samlResponse"
          value={props.samlResponse}
        />
        <input
          type="hidden"
          name="RelayState"
          id="relayState"
          value={props.relayState}
        />
      </form>
    </React.Fragment>
  );
};

export default RedirectForm;
