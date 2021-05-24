import React from "react";
import "./App.css";
import { fetchUtils, Admin, Resource } from "react-admin";

import { RestaurantList, RestaurantEdit } from "./restaurants";
import { UsersList, UsersEdit } from "./users";
// import { CollectionsList, CollectionsEdit } from './collections';

import jsonServerProvider from "ra-data-json-server";
import Constants from "./constants/constants";
import authProvider, { authHeaderObject } from "./reactAdmin/authProvider";

const httpClient = (url, options = {}) => {
  if (!options.headers) {
    options.headers = new Headers({ Accept: "application/json" });
  }

  const { client, uid, "access-token": accessToken } = authHeaderObject();

  options.headers.set("uid", uid);
  options.headers.set("client", client);
  options.headers.set("access-token", accessToken);

  return fetchUtils.fetchJson(url, options);
};

const dataProvider = jsonServerProvider(Constants.API_ROOT, httpClient);

const App = () => {
  return (
    <Admin dataProvider={dataProvider} authProvider={authProvider}>
      <Resource name="users" list={UsersList} edit={UsersEdit} />
      <Resource
        name="restaurants"
        list={RestaurantList}
        edit={RestaurantEdit}
      />
    </Admin>
  );
};

export default App;
